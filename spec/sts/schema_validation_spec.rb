# frozen_string_literal: true

# Schema validation tests: verify that the OIML STS XML output is
# structurally valid against:
#
# 1. The NISO STS 1.0 extended XSD (loaded from spec/fixtures/schemas/).
#    Known STS 1.2 additions (<processing-meta>, @dtd-version="1.2") are
#    acceptable deviations.
# 2. The gem's own Schematron-equivalent Ruby rules (OIML X 999 Clause 6).
# 3. Basic XML well-formedness.
RSpec.describe "OIML STS schema validation", :validation do
  include Metanorma::Oiml::Sts::Spec::XsdValidator

  FIXTURES = %w[
    sample.xml
    complete_metadata.xml
    nested_sections.xml
    inline_markup.xml
    lists.xml
    tables.xml
    figures.xml
    formulae.xml
    notes_examples.xml
    bibliography.xml
    annexes.xml
  ].freeze

  def convert_fixture(name)
    Metanorma::Oiml::Sts.convert(File.read(FIXTURES_ROOT.join(name)))
  end

  describe "XSD schema loads cleanly" do
    it "has zero errors on load" do
      expect(schema.errors).to be_empty
    end
  end

  FIXTURES.each do |fixture|
    describe "#{fixture} output" do
      let(:sts_xml) { convert_fixture(fixture) }

      it "is well-formed XML" do
        doc = Nokogiri::XML(sts_xml)
        expect(doc.errors).to be_empty, "XML parse errors: #{doc.errors.map(&:message).join('; ')}"
      end

      it "has a <standard> root element" do
        doc = Nokogiri::XML(sts_xml)
        expect(doc.root.name).to eq("standard").or eq("adoption")
      end

      it "passes XSD validation modulo STS 1.2 additions" do
        unexpected = unexpected_errors(sts_xml)
        expect(unexpected).to be_empty,
                              "Unexpected XSD errors:\n#{unexpected.map(&:message).join("\n")}"
      end

      it "passes the gem's Schematron rules" do
        report = Metanorma::Oiml::Sts.validate(sts_xml)
        expect(report).to be_valid, report.to_s
      end
    end
  end

  describe "specific structural requirements" do
    let(:sts_xml) { convert_fixture("sample.xml") }
    let(:doc) { Nokogiri::XML(sts_xml) }

    it "root <standard> carries @xml:lang" do
      expect(doc.root["xml:lang"]).to eq("en")
    end

    it "root <standard> carries @dtd-version" do
      expect(doc.root["dtd-version"]).to eq("1.2")
    end

    it "has <processing-meta> as first child of <standard>" do
      first = doc.root.element_children.first
      expect(first.name).to eq("processing-meta")
    end

    it "<processing-meta> declares all five modeling attributes" do
      meta = doc.at_xpath("//processing-meta")
      expect(meta["tagset-family"]).to eq("sts")
      expect(meta["base-tagset"]).to eq("interchange")
      expect(meta["table-model"]).to eq("xhtml")
      expect(meta["mathml"]).to eq("MathML 3.0")
      expect(meta["terminology-model"]).to eq("tbx")
    end

    it "has <front> containing <iso-meta>" do
      expect(doc.at_xpath("//front/iso-meta")).not_to be_nil
    end

    it "<iso-meta> has a <doc-identifier>" do
      expect(doc.at_xpath("//iso-meta/std-ident")).not_to be_nil
    end

    it "<iso-meta> has <permissions> with copyright info" do
      expect(doc.at_xpath("//iso-meta/permissions/copyright-holder")).not_to be_nil
    end
  end
end
