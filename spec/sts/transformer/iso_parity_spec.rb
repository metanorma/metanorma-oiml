# frozen_string_literal: true

require "nokogiri"

RSpec.describe "reconciled OIML STS mirrors" do
  def convert_sections(sections, extra = "")
    xml = <<~XML
      <metanorma xmlns="https://www.metanorma.org/ns/standoc" type="presentation" flavor="oiml">
        <bibdata type="standard">
          <title language="en" type="main">Parity sample</title>
          <docidentifier>OIML R 7</docidentifier><language>en</language>
        </bibdata>
        <sections>#{sections}</sections>#{extra}
      </metanorma>
    XML
    Nokogiri::XML(Metanorma::Oiml::Sts.convert(xml)).tap(&:remove_namespaces!)
  end

  it "keeps interleaved paragraph, list, note and nested clause order" do
    doc = convert_sections(<<~XML)
      <clause id="s"><title>Scope</title>
        <p id="p1">Before</p>
        <ul><li><p>Item</p></li></ul>
        <p id="p2">After</p>
        <note autonum="2"><p>Trailing note</p></note>
        <clause id="nested"><title>Nested</title><p>Nested content</p></clause>
        <p id="p3">Last</p>
      </clause>
    XML
    expect(doc.at_xpath('//sec[@id="s"]').element_children.map(&:name))
      .to eq(%w[title p list p non-normative-note sec p])
    expect(doc.at_xpath('//non-normative-note/label').text).to eq("NOTE 2")
  end

  it "keeps ordered item designations and note labels ahead of content" do
    doc = convert_sections(<<~XML)
      <clause id="s"><title>Lists</title>
        <ol type="alphabet"><li><p>First</p></li><li><p>Second</p></li></ol>
        <example autonum="3"><p>An example</p></example>
      </clause>
    XML
    expect(doc.at_xpath('//list')['list-type']).to eq("alpha-lower")
    expect(doc.xpath('//list-item/label').map(&:text)).to eq(["a)", "b)"])
    example = doc.at_xpath('//non-normative-example')
    expect(example.element_children.map(&:name)).to eq(%w[label p])
    expect(example.at_xpath('label').text).to eq("EXAMPLE 3")
  end

  it "preserves external link targets through the typed href attribute" do
    doc = convert_sections('<clause id="s"><title>Links</title><p>See <link target="https://example.org/resource">the resource</link>.</p></clause>')
    expect(doc.at_xpath('//ext-link')['href']).to eq("https://example.org/resource")
    expect(doc.at_xpath('//ext-link').text).to eq("the resource")
  end

  it "emits graphics with OIML asset paths and resolves forward figure references" do
    doc = convert_sections(<<~XML)
      <clause id="s"><title>Figures</title>
        <p>See <xref target="image-source" style="figure"/>.</p>
        <figure id="image-source" autonum="1"><name>Diagram</name><image src="images/diagram.svg" mimetype="image/svg+xml"/></figure>
      </clause>
    XML
    expect(doc.at_xpath('//graphic')['href']).to eq("images/diagram.svg")
    expect(doc.at_xpath('//xref')['rid']).to eq(doc.at_xpath('//fig')['id'])
    expect(doc.at_xpath('//xref')['ref-type']).to eq("fig")
  end

  it "resolves forward annex references while keeping OIML body prefaces" do
    doc = convert_sections('<clause id="s"><title>Scope</title><p>See <xref target="annex-source" style="clause"/>.</p></clause>', <<~XML)
      <preface><foreword id="fw"><title>Foreword</title><p>OIML foreword</p></foreword></preface>
      <annex id="annex-source" autonum="A" obligation="informative"><title>Annex title</title><p>Annex body</p></annex>
    XML
    expect(doc.at_xpath('//body/sec[title="Foreword"]')).not_to be_nil
    expect(doc.at_xpath('//front/sec')).to be_nil
    app = doc.at_xpath('//back/app-group/app')
    expect(app['id']).to eq("sec_A")
    expect(app.at_xpath('p').text).to eq("Annex body")
    expect(doc.at_xpath('//xref')['rid']).to eq(app['id'])
    expect(doc.at_xpath('//xref')['ref-type']).to eq("app")
  end

  it "registers bibliography kinds before transforming in-body citations" do
    doc = convert_sections('<clause id="s"><title>Scope</title><p>See <xref target="b1"/>.</p></clause>', <<~XML)
      <bibliography><references id="bibliography"><title>Bibliography</title>
        <bibitem id="b1"><docidentifier>OIML R 1:2020</docidentifier><formattedref>A reference</formattedref></bibitem>
      </references></bibliography>
    XML
    expect(doc.at_xpath('//xref')['ref-type']).to eq("bibr")
    expect(doc.at_xpath('//xref')['rid']).to eq(doc.at_xpath('//ref')['id'])
  end

  it "keeps OIML terms as ordinary sections with resolvable source anchors" do
    doc = convert_sections(<<~XML)
      <clause id="s"><title>Scope</title><p>See <xref target="term1" style="clause"/>.</p></clause>
      <terms id="terms"><title>Terms and definitions</title>
        <term id="term1"><preferred><expression><name>sample</name></expression></preferred></term>
      </terms>
    XML
    expect(doc.at_xpath('//xref')['rid']).to eq("term1")
    expect(doc.at_xpath('//sec[@id="term1"]')).not_to be_nil
  end

  it "claims unique ids even when a generated suffix is requested explicitly" do
    ids = Metanorma::Oiml::Sts::Transformer::IdGenerator.new
    issued = [ids.claim("sec_A"), ids.claim("sec_A"), ids.claim("sec_A_1")]
    expect(issued.uniq).to eq(issued)
  end

  it "reuses the claimed identity of an anonymous annex" do
    ids = Metanorma::Oiml::Sts::Transformer::IdGenerator.new
    annex = Metanorma::Oiml::Document::Root.from_xml(<<~XML).annex.first
      <metanorma xmlns="https://www.metanorma.org/ns/standoc"><annex><title>Annex</title></annex></metanorma>
    XML
    expect(ids.id_for_annex(annex, nil)).to eq("sec_A")
    expect(ids.id_for_annex(annex, nil)).to eq("sec_A")
  end
  it "maps references by the emitted identity when an annex id needs a suffix" do
    doc = convert_sections('<clause id="s"><title>Scope</title><p>See <xref target="second-annex" style="clause"/>.</p></clause>', <<~XML)
      <annex id="first-annex" autonum="A"><title>First</title><p>First annex</p></annex>
      <annex id="second-annex" autonum="A"><title>Second</title><p>Second annex</p></annex>
    XML
    expect(doc.at_xpath('//xref')['rid']).to eq("sec_A_1")
    expect(doc.at_xpath('//xref')['ref-type']).to eq("app")
  end

end
