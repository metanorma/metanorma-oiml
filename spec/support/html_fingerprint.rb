# frozen_string_literal: true

require "nokogiri"
require "set"

module Metanorma
  module Oiml
    module Sts
      module Spec
        # Extracts a content fingerprint from an HTML document. The
        # fingerprint is a set of normalized content entries that capture
        # the document's semantic content independent of formatting.
        #
        # Two HTMLs with the same fingerprint have equivalent content.
        # This is the basis for the 100% content parity test: the
        # Metanorma HTML fingerprint must be a subset of the STS HTML
        # fingerprint.
        module HtmlFingerprint
          module_function

          # Extract a content fingerprint from an HTML string.
          # Returns a hash of Sets keyed by content type.
          def extract(html)
            doc = Nokogiri::HTML(html)
            {
              paragraphs: extract_paragraphs(doc),
              headings: extract_headings(doc),
              table_cells: extract_table_cells(doc),
              list_items: extract_list_items(doc),
              images: extract_images(doc),
              links: extract_links(doc),
              xrefs: extract_xrefs(doc)
            }
          end

          # Returns true if every entry in `subset` appears in `superset`.
          def subset?(subset, superset)
            subset.all? do |key, sub_values|
              super_values = superset[key]
              missing = sub_values - super_values
              if missing.any?
                @missing ||= {}
                @missing[key] = missing
                false
              else
                true
              end
            end
          end

          attr_reader :missing

          # Returns all missing entries from the last `subset?` call.
          def missing_entries
            @missing || {}
          end

          def reset_missing!
            @missing = nil
          end

          # -- extraction helpers --

          def extract_paragraphs(doc)
            doc.xpath("//p").map { |p| normalize(p.text) }.reject(&:empty?).to_set
          end

          def extract_headings(doc)
            doc.xpath("//h1 | //h2 | //h3 | //h4 | //h5 | //h6 | //title").map do |h|
              normalize(h.text)
            end.reject(&:empty?).to_set
          end

          def extract_table_cells(doc)
            doc.xpath("//td | //th").map { |c| normalize(c.text) }.reject(&:empty?).to_set
          end

          def extract_list_items(doc)
            doc.xpath("//li").map { |li| normalize(li.text) }.reject(&:empty?).to_set
          end

          def extract_images(doc)
            doc.xpath("//img/@src").map(&:value).to_set
          end

          def extract_links(doc)
            doc.xpath("//a/@href").map(&:value).reject { |h| h.start_with?("#") }.to_set
          end

          def extract_xrefs(doc)
            doc.xpath("//a[starts-with(@href,'#')]/@href").map { |h| h.value.sub("#", "") }.to_set
          end

          def normalize(text)
            text.to_s.strip.gsub(/[\s ]+/, " ").downcase
          end
        end
      end
    end
  end
end
