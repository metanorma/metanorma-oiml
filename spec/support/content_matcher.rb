# frozen_string_literal: true

require "nokogiri"

module Metanorma
  module Oiml
    module Sts
      module Spec
        # Helper that compares the SEMANTIC content of a Metanorma
        # presentation XML document against its OIML NISO STS output.
        #
        # The presentation XML contains substantial rendering duplication
        # (`<fmt-title>` alongside `<title>`, `<fmt-xref>` alongside
        # `<xref>`, `<semx>` wrappers, asciimath fallback alongside MathML,
        # `<localized-string>` variants, etc.). This helper strips those
        # rendering-only elements from the source before comparing, so the
        # comparison reflects true semantic content rather than raw text
        # volume.
        module ContentMatcher
          SOURCE_NS = { "m" => "https://www.metanorma.org/ns/standoc" }.freeze

          # Elements that are pure rendering chrome in the presentation XML.
          # Their content is either duplicated elsewhere or is display-only.
          CHROME_TAGS = %w[
            fmt-title
            fmt-name
            fmt-xref
            fmt-link
            fmt-xref-label
            fmt-identifier
            fmt-stem
            fmt-footnote-container
            fmt-fn-body
            fmt-fn-label
            asciimath
            localized-strings
            localized-string
            presentation-metadata
            semantic-metadata
            metanorma-extension
            boilerplate
            tab
            fmt-autonum-delim
            fmt-caption-label
            fmt-element-name
          ].freeze

          module_function

          # Returns the set of distinct words in a document's text content,
          # suitable for set-comparison. Strips all whitespace and case.
          def word_set(doc, chrome_tags: CHROME_TAGS)
            stripped = strip_chrome(doc.dup, chrome_tags)
            text = stripped.xpath("//text()").map(&:text).join(" ")
            text.downcase.gsub(/[^a-z0-9\s]/i, " ").split.to_set
          end

          # Returns a hash of semantic element counts (excluding chrome).
          def element_inventory(doc, chrome_tags: CHROME_TAGS)
            stripped = strip_chrome(doc.dup, chrome_tags)
            counts = Hash.new(0)
            stripped.xpath("//*").each { |n| counts[n.name] += 1 }
            counts
          end

          # Returns the total character count of semantic text.
          def text_length(doc, chrome_tags: CHROME_TAGS)
            stripped = strip_chrome(doc.dup, chrome_tags)
            stripped.xpath("//text()").sum { |t| t.text.strip.size }
          end

          # Returns all section titles in order.
          def section_titles(doc)
            doc.xpath("//m:sections//m:clause/m:title",
                      SOURCE_NS).map(&:text).map(&:strip)
          end

          # Returns the count of table cells (td + th) in the document.
          def table_cell_count(doc)
            doc.xpath("//m:td | //m:th", SOURCE_NS).size
          end

          # Strips rendering chrome from a Nokogiri document (in place).
          def strip_chrome(doc, chrome_tags = CHROME_TAGS)
            chrome_tags.each do |tag|
              doc.xpath("//m:#{tag}", SOURCE_NS).each(&:remove)
            end
            # Also remove any remaining fmt-* elements
            doc.xpath("//*[starts-with(local-name(), 'fmt-')]").each(&:remove)
            doc
          end

          # Returns the STS output for a given source XML string.
          def convert(source_xml)
            Metanorma::Oiml::Sts.convert(source_xml)
          end

          # Parse a string as XML.
          def parse(xml)
            Nokogiri::XML(xml) { |config| config.noblanks }
          end

          # Returns [source_semantic_words, sts_words] as sets.
          def word_sets(source_xml)
            source_doc = parse(source_xml)
            sts_xml = convert(source_xml)
            sts_doc = parse(sts_xml)
            [word_set(source_doc), word_set(sts_doc)]
          end

          # Returns the fraction (0..1) of source semantic words that appear
          # in the STS output. Strips rendering chrome first so duplication
          # doesn't inflate the denominator.
          def word_retention(source_xml)
            src_words, sts_words = word_sets(source_xml)
            return 1.0 if src_words.empty?

            retained = src_words & sts_words
            retained.size.to_f / src_words.size
          end

          # Returns the set of source semantic words NOT found in STS.
          # A non-empty result means content was lost during conversion.
          def missing_words(source_xml)
            src_words, sts_words = word_sets(source_xml)
            src_words - sts_words
          end

          # Build a per-element content inventory of a source document.
          # Each entry is a string key like "clause:Scope" or "td:±0.1%"
          # derived from the element's semantic content. The STS output
          # should contain every key.
          def semantic_keys(doc, chrome_tags: CHROME_TAGS)
            stripped = strip_chrome(doc.dup, chrome_tags)
            keys = []

            stripped.xpath("//m:clause/m:title", SOURCE_NS).each do |t|
              keys << "clause_title:#{t.text.strip}"
            end
            stripped.xpath("//m:p", SOURCE_NS).each do |p|
              text = p.text.strip
              keys << "p:#{text}" unless text.empty?
            end
            stripped.xpath("//m:td | //m:th", SOURCE_NS).each do |cell|
              text = cell.text.strip
              keys << "cell:#{text}" unless text.empty?
            end
            stripped.xpath("//m:li", SOURCE_NS).each do |li|
              text = li.text.strip
              keys << "li:#{text}" unless text.empty?
            end
            stripped.xpath("//m:figure/m:name | //m:figure/m:fmt-name", SOURCE_NS).each do |n|
              keys << "figure_name:#{n.text.strip}"
            end
            stripped.xpath("//m:image/@src", SOURCE_NS).each do |src|
              keys << "image_src:#{src.value}"
            end
            stripped.xpath("//m:docidentifier", SOURCE_NS).each do |d|
              keys << "docid:#{d.text.strip}"
            end
            keys
          end

          # Cross-reference integrity: returns a list of source xref targets
          # (the @target/@refid values) that must appear as @rid in the STS
          # output's <xref> elements.
          def source_xref_targets(doc)
            doc.xpath("//m:xref/@target | //m:xref/@refid | //m:xref/@to",
                      SOURCE_NS).map(&:value).compact.uniq
          end

          # Returns the set of @rid values in STS <xref> elements.
          def sts_xref_rids(doc)
            doc.xpath("//xref/@rid").map(&:value).compact.uniq
          end

          # Returns @id values declared anywhere in a document.
          def all_ids(doc)
            doc.xpath("//@id").map(&:value).compact.uniq
          end

          # Count of a specific source element tag, after stripping chrome.
          def source_count(doc, mn_tag)
            stripped = strip_chrome(doc.dup)
            stripped.xpath("//m:#{mn_tag}", SOURCE_NS).size
          end
        end
      end
    end
  end
end
