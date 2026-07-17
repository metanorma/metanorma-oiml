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
    it { expect(doc.copyright_year).to eq("1979") }
    it { expect(doc.sections.size).to eq(1) }
    it { expect(doc.annexes).to be_empty }
    it { expect(doc).to be_front }
    it { expect(doc).not_to be_has_back }
  end

  describe Metanorma::Oiml::Sts::Transformer::ModelBuilder do
    it "builds a standard model via factory methods" do
      standard = described_class.standard(lang: "en", dtd_version: "1.2")
      expect(standard).to be_a(::Sts::IsoSts::Standard)
      expect(standard.lang).to eq("en")
      xml = standard.to_xml
      expect(xml).to include("<standard")
      expect(xml).to include('lang="en"')
    end

    it "builds a sec with title and content" do
      sec = described_class.sec(title: "Scope")
      expect(sec).to be_a(::Sts::IsoSts::Sec)
      expect(sec.to_xml).to include("<title>Scope</title>")
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::IdGenerator do
    let(:gen) { described_class.new }

    # Tiny stand-in for a typed source model: exposes `id` and `title`
    # the way IsoClauseSection / ParagraphBlock do.
    stub_model = Struct.new(:id, :title) do
      def each_mixed_content
        yield(title.to_s) unless title.nil?
      end
    end

    it "preserves the source @id verbatim when present" do
      node = stub_model.new("s_scope", "Scope")
      expect(gen.id_for(node, prefix: "sec")).to eq("s_scope")
    end

    it "derives a semantic id from the title when no source @id" do
      node = stub_model.new(nil, "Scope")
      expect(gen.id_for(node, prefix: "sec")).to eq("sec_scope")
    end

    it "falls back to a numbered id when title is empty" do
      node = stub_model.new(nil, "")
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
      expect(output).to include("<originator>OIML R</originator>")
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

    it "is instantiated with a context" do
      expect { described_class.new(context) }.not_to raise_error
    end
  end

  describe Metanorma::Oiml::Sts::Transformer::ReferenceTransformer do
    let(:source) { Metanorma::Oiml::Sts::Transformer::SourceDocument.parse(input) }
    let(:context) { Metanorma::Oiml::Sts::Transformer::Context.new(source) }

    it "is instantiated with a context" do
      expect { described_class.new(context) }.not_to raise_error
    end
  end
end
