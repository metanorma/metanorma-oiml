# frozen_string_literal: true

# Real document regression tests.
#
# These tests convert actual OIML publication presentation XMLs from
# ~/src/mn/mn-samples-oiml/ and verify:
# - The conversion succeeds
# - The output is well-formed XML
# - The output passes XSD validation (modulo STS 1.2 additions)
# - The output passes Schematron rules
# - Semantic word retention meets a reasonable threshold
# - Element counts don't drop significantly
#
# If ~/src/mn/mn-samples-oiml/ is not present, these tests are skipped.
RSpec.describe "OIML STS real document regression", :real do
  include Metanorma::Oiml::Sts::Spec::ContentMatcher
  include Metanorma::Oiml::Sts::Spec::XsdValidator

  SOURCE_NS = Metanorma::Oiml::Sts::Spec::ContentMatcher::SOURCE_NS.freeze

  SAMPLES_ROOT = Pathname.new(File.expand_path("~/src/mn/mn-samples-oiml")).freeze
  TEST_DOCS = %w[
    r007-e79
    oiml-cs-pd-08
    b022-e23
    d030
    oiml-cs-od-02
  ].freeze

  before(:all) do
    unless SAMPLES_ROOT.exist?
      skip "mn-samples-oiml not found at #{SAMPLES_ROOT}; skipping real document tests"
    end
  end

  def presentation_xml_for(slug)
    path = SAMPLES_ROOT.join("sources", slug, "document.presentation.xml")
    skip "#{slug} presentation XML not found" unless path.exist?

    path.read
  end

  TEST_DOCS.each do |slug|
    describe slug do
      let(:source_xml) { presentation_xml_for(slug) }
      let(:sts_xml) { Metanorma::Oiml::Sts.convert(source_xml) }
      let(:sts_doc) { parse(sts_xml) }
      let(:source_doc) { parse(source_xml) }

      it "converts without error" do
        expect(sts_xml).to be_a(String)
        expect(sts_xml).to include("<standard")
      end

      it "produces well-formed XML" do
        expect(sts_doc.errors).to be_empty,
               "XML parse errors: #{sts_doc.errors.map(&:message).first(3).join('; ')}"
      end

      it "passes XSD validation modulo STS 1.2 additions" do
        unexpected = unexpected_errors(sts_xml)
        expect(unexpected).to be_empty,
                              "Unexpected XSD errors:\n#{unexpected.map(&:message).first(5).join("\n")}"
      end

      it "passes Schematron validation (or has only std-missing-date errors)" do
        report = Metanorma::Oiml::Sts.validate(sts_xml)
        # Real documents may have bibitems without <pub-date>, which is a
        # data issue not a conversion issue. Filter those out.
        conversion_errors = report.errors.reject do |e|
          e.rule_id == "oiml-x999-std-title-and-date"
        end
        expect(conversion_errors).to be_empty,
                                     conversion_errors.map { |e| "[#{e.rule_id}] #{e.message}" }.join("\n")
      end

      it "retains at least 75% of semantic words" do
        retention = word_retention(source_xml)
        expect(retention).to be >= 0.75,
                             "Word retention too low: #{(retention * 100).round(1)}%"
      end

      it "preserves most clauses (within 20%)" do
        src_clauses = Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, "clause")
        sts_secs = sts_doc.xpath("//sec").size + sts_doc.xpath("//app").size
        if src_clauses > 0
          ratio = sts_secs.to_f / src_clauses
          expect(ratio).to be >= 0.8,
                           "Clause retention too low: source=#{src_clauses}, sts=#{sts_secs}"
        end
      end

      it "preserves most tables (within 20%)" do
        src_tables = Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, "table")
        next if src_tables.zero?

        sts_tables = sts_doc.xpath("//table-wrap").size
        ratio = sts_tables.to_f / src_tables
        expect(ratio).to be >= 0.8,
                         "Table retention: source=#{src_tables}, sts=#{sts_tables}"
      end

      it "preserves most table cells (within 30%)" do
        src_cells = Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, "td") + Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, "th")
        next if src_cells.zero?

        sts_cells = sts_doc.xpath("//td").size + sts_doc.xpath("//th").size
        ratio = sts_cells.to_f / src_cells
        expect(ratio).to be >= 0.7,
                         "Cell retention: source=#{src_cells}, sts=#{sts_cells}"
      end

      it "preserves most figures (within 20%)" do
        src_figs = Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, "figure")
        next if src_figs.zero?

        sts_figs = sts_doc.xpath("//fig").size
        ratio = sts_figs.to_f / src_figs
        expect(ratio).to be >= 0.8,
                         "Figure retention: source=#{src_figs}, sts=#{sts_figs}"
      end
    end
  end
end
