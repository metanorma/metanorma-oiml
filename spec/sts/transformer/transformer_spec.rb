# frozen_string_literal: true

RSpec.describe Metanorma::Oiml::Sts::Transformer do
  let(:input) { File.read(FIXTURES_ROOT.join("sample.xml")) }

  describe ".convert" do
    it "returns STS XML via the Transformer namespace" do
      output = described_class.convert(input)
      expect(output).to include("<standard")
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::SourceDocument do
    let(:doc) { described_class.parse(input) }

    it { expect(doc.docidentifier).to eq("OIML R 7") }
    it { expect(doc.language).to eq("en") }
    it { expect(doc.doctype).to eq("international-recommendation") }
    it { expect(doc.copyright_year).to eq("1979") }
    it { expect(doc.stage_code).to eq("60") }
    it { expect(doc.sections.size).to eq(1) }
    it { expect(doc.annexes).to be_empty }
    it { expect(doc).to be_front }
    it { expect(doc).not_to be_has_back }
  end

  describe Metanorma::Oiml::Sts::Transformer::StsXml do
    let(:sts) { described_class.new }

    it "emits a standard root with namespaces" do
      sts.standard("xml:lang" => "en", "xmlns:xlink" => described_class::XLINK_NS) do
        sts.front
        sts.body
      end
      out = sts.to_xml
      expect(out).to include("<standard")
      expect(out).to include('xml:lang="en"')
    end

    it "supports hyphenated tag names" do
      sts.standard do
        sts.iso_meta { sts.doc_identifier("OIML R 7") }
      end
      expect(sts.to_xml).to include("<doc-identifier>OIML R 7</doc-identifier>")
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::IdGenerator do
    let(:gen) { described_class.new }

    it "derives a semantic id from the title" do
      node = Nokogiri::XML(<<~XML).root
        <clause xmlns="https://www.metanorma.org/ns/standoc" id="s_scope">
          <title>Scope</title>
        </clause>
      XML
      expect(gen.id_for(node, prefix: "sec")).to eq("sec_scope")
    end

    it "falls back to a numbered id when title is empty" do
      node = Nokogiri::XML('<clause xmlns="https://www.metanorma.org/ns/standoc"/>').root
      expect(gen.id_for(node, prefix: "sec")).to eq("sec_1")
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::FootnoteCollector do
    let(:col) { described_class.new }

    it "returns a unique sts id per source id" do
      expect(col.register("fn_a")).to eq("fn_1")
      expect(col.register("fn_b")).to eq("fn_2")
    end

    it "returns the same id on repeat registration" do
      first = col.register("fn_a")
      expect(col.register("fn_a")).to eq(first)
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::DocumentTransformer do
    let(:source) { Metanorma::Oiml::Sts::Transformer::SourceDocument.parse(input) }
    let(:context) { Metanorma::Oiml::Sts::Transformer::Context.new(source) }
    let(:output) { described_class.new(context).transform_to_xml(source) }

    it "emits <standard> with the source language" do
      expect(output).to include("<standard")
      expect(output).to include('xml:lang="en"')
    end

    it "emits <processing-meta> with OIML defaults" do
      expect(output).to include('tagset-family="sts"')
      expect(output).to include('table-model="xhtml"')
      expect(output).to include('mathml="MathML 3.0"')
    end

    it "emits the OIML identifier" do
      expect(output).to include("<doc-identifier>OIML R 7</doc-identifier>")
    end

    it "records the OIML series letter" do
      expect(output).to include("<meta-value>R</meta-value>")
    end

    it "does not leak metanorma namespace" do
      expect(output).not_to include("metanorma.org/ns/standoc")
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::InlineTransformer do
    let(:source) { Metanorma::Oiml::Sts::Transformer::SourceDocument.parse(input) }
    let(:context) { Metanorma::Oiml::Sts::Transformer::Context.new(source) }
    let(:transformer) { described_class.new(context) }
    let(:sts) { Metanorma::Oiml::Sts::Transformer::StsXml.new }

    def emit(snippet)
      node = Nokogiri::XML(snippet).root
      sts.standard { sts.body { sts.p { transformer.transform_children(node, sts) } } }
      sts.to_xml
    end

    it "maps <em> → <italic>" do
      out = emit('<p xmlns="https://www.metanorma.org/ns/standoc"><em>italic</em></p>')
      expect(out).to include("<italic>italic</italic>")
    end

    it "maps <xref type='clause'> → <xref ref-type='sec'>" do
      out = emit('<p xmlns="https://www.metanorma.org/ns/standoc"><xref target="s_scope" type="clause">Scope</xref></p>')
      expect(out).to include('<xref rid="s_scope" ref-type="sec">')
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::ReferenceTransformer do
    let(:source) { Metanorma::Oiml::Sts::Transformer::SourceDocument.parse(input) }
    let(:context) { Metanorma::Oiml::Sts::Transformer::Context.new(source) }
    let(:transformer) { described_class.new(context) }
    let(:sts) { Metanorma::Oiml::Sts::Transformer::StsXml.new }

    it "emits <std> with <title> and <pub-date>" do
      node = Nokogiri::XML(<<~XML).root
        <bibitem xmlns="https://www.metanorma.org/ns/standoc" id="iso-123">
          <docidentifier>ISO 123</docidentifier>
          <title>Sample standard</title>
          <date type="published"><on>2024</on></date>
        </bibitem>
      XML
      sts.standard { sts.back { transformer.transform(node, sts) } }
      out = sts.to_xml
      expect(out).to include("<std>")
      expect(out).to include("<title>Sample standard</title>")
      expect(out).to include("<pub-date>")
      expect(out).to include("<year>2024</year>")
    end
  end
end
