# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module ParityValidator
        # Text normalisation shared by all comparison logic.
        class Normaliser
          CHROME_SELECTORS = %w[
            script style head nav
            .title-section .prefatory-section
            .toc #toc
            .coverpage_docnumber .coverpage_techcommittee
            .coverpage_docstage .coverpage_warning
            .doctitle-fr
            .btn .collapse-button .collapse-group
            .anchor .header
          ].freeze

          BLOCK_BOUNDARY_ELEMENTS =
            %w[p div td th li h1 h2 h3 h4 h5 h6 section table tr
               ul ol dl dt dd].freeze

          def self.strip_chrome(html)
            doc = Nokogiri::HTML(html)
            CHROME_SELECTORS.each { |sel| doc.css(sel).remove }
            doc.css("body").first&.to_html || doc.to_html
          end

          def self.normalise(text)
            new_text = text.to_s
            new_text = unify_block_boundaries(new_text)
            # Collapse non-breaking spaces (U+00A0) and regular whitespace.
            new_text = new_text.gsub(/[⁡⁢⁣⁤]/, "")
            new_text = new_text.gsub(/[ \s]+/, " ")
            new_text = unify_dashes(new_text)
            new_text = new_text.gsub(/\s+/, " ").strip.downcase
            new_text
          end

          def self.unify_block_boundaries(text)
            regex = /(<\/(?:#{BLOCK_BOUNDARY_ELEMENTS.join("|")})>)/i
            text.gsub(regex, " \\1")
          end

          def self.unify_dashes(text)
            text.gsub(/[–—−]/, "-")
          end

          def self.strip_section_number(text)
            text.to_s.gsub(/\A\s*\d+(\.\d+)*[\s ]+/, "")
          end

          def self.strip_anchor_brackets(text)
            text.to_s.gsub(/\[([A-Z][A-Z0-9_]*)\]/, '\1')
          end

          def self.heading_text(text)
            normalise(strip_section_number(text))
          end

          def self.paragraph_text(text)
            normalise(strip_anchor_brackets(text))
          end
        end
      end
    end
  end
end
