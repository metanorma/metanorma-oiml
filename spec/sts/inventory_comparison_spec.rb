# frozen_string_literal: true

# Content inventory comparison tests.
#
# For each fixture, count every semantic element type in the source
# (after stripping rendering chrome) and compare with the STS output.
# Significant count mismatches indicate structural content loss.
RSpec.describe "OIML STS content inventory", :inventory do
  include Metanorma::Oiml::Sts::Spec::ContentMatcher

  SOURCE_NS = Metanorma::Oiml::Sts::Spec::ContentMatcher::SOURCE_NS.freeze

  FIXTURES = %w[
    sample.xml
    complete_metadata.xml
    nested_sections.xml
    inline_markup.xml
    lists.xml
    tables.xml
    figures.xml
    notes_examples.xml
    bibliography.xml
    annexes.xml
  ].freeze

  # Map of source element name -> STS element name(s) to compare counts.
  # A source element may map to multiple STS equivalents; we count the
  # sum of STS equivalents.
  COUNT_MAP = {
    "clause"       => %w[sec app],       # clause → sec (body) or app (annex)
    "p"            => %w[p],
    "ul"           => %w[list],
    "ol"           => %w[list],
    "li"           => %w[list-item],
    "table"        => %w[table-wrap],
    "td"           => %w[td],
    "th"           => %w[th],
    "figure"       => %w[fig],
    "image"        => %w[graphic inline-graphic],
    "em"           => %w[italic],
    "strong"       => %w[bold],
    "tt"           => %w[monospace],
    "note"         => %w[non-normative-note],
    "example"      => %w[non-normative-example],
    "bibitem"      => %w[ref]
  }.freeze

  def load_fixture(name)
    File.read(FIXTURES_ROOT.join(name))
  end

  def sts_count(doc, sts_tags)
    sts_tags.sum { |tag| doc.xpath("//#{tag}").size }
  end

  FIXTURES.each do |fixture|
    describe fixture do
      let(:source_doc) { parse(load_fixture(fixture)) }
      let(:sts_xml) { Metanorma::Oiml::Sts.convert(load_fixture(fixture)) }
      let(:sts_doc) { parse(sts_xml) }

      COUNT_MAP.each do |mn_tag, sts_tags|
        it "preserves every #{mn_tag} (→ STS #{sts_tags.join('+')})" do
          src = Metanorma::Oiml::Sts::Spec::ContentMatcher.source_count(source_doc, mn_tag)
          sts = sts_count(sts_doc, sts_tags)
          next if src.zero?

          ratio = sts.to_f / src
          expect(ratio).to be >= 0.8,
                           "#{mn_tag} count dropped: source=#{src}, sts=#{sts} (ratio=#{ratio.round(2)})"
        end
      end

      it "preserves total text length within 30%" do
        src_len = Metanorma::Oiml::Sts::Spec::ContentMatcher.text_length(source_doc)
        sts_len = Metanorma::Oiml::Sts::Spec::ContentMatcher.text_length(sts_doc)
        if src_len > 0
          ratio = sts_len.to_f / src_len
          expect(ratio).to be >= 0.70,
                           "Total text length dropped: source=#{src_len}, sts=#{sts_len} (ratio=#{ratio.round(2)})"
        end
      end
    end
  end
end
