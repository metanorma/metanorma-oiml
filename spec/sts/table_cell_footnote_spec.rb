# frozen_string_literal: true

# A footnote inside a table cell converts to a <fn> child of the <td>
# instead of crashing the whole conversion (the trunk's build_fn named
# the nonexistent Sts::TbxIsoTml::Fn; the sts-ruby class is
# Sts::NisoSts::Fn — the mirrored ISO tree and the shared engine both
# use it).
RSpec.describe "table cell footnotes" do
  let(:xml) do
    <<~XML
      <metanorma>
        <bibdata>
          <title language="en" type="main">T</title>
          <docidentifier>OIML R 60:2025</docidentifier>
          <language>en</language>
        </bibdata>
        <sections>
          <clause id="c1">
            <title>Body</title>
            <table id="tb1">
              <tbody>
                <tr><th>H</th><td>Cell<fn id="fn1" reference="a"><p id="fp1">Alpha body.</p><p id="fp2">Beta body.</p></fn></td></tr>
              </tbody>
            </table>
          </clause>
        </sections>
      </metanorma>
    XML
  end

  let(:doc) { Nokogiri::XML(Metanorma::Oiml::Sts.convert(xml)) }

  it "emits one <fn> inside the cell, keeping its id" do
    fns = doc.xpath("//body//table-wrap//td/fn")
    expect(fns.map { |f| f["id"] }).to eq(["fn1"])
  end

  it "keeps every footnote paragraph, in order" do
    paras = doc.xpath("//body//table-wrap//td/fn/p").map(&:text)
    expect(paras).to match([a_string_including("Alpha body."), a_string_including("Beta body.")])
  end
end
