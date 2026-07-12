# frozen_string_literal: true

require "nokogiri"
require "metanorma/document"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Parsed-input façade over a Metanorma OIML presentation XML document.
        #
        # Uses `Metanorma::OimlDocument::Root.from_xml` for typed parsing of
        # the high-level bibliographic metadata, and Nokogiri for everything
        # else (body content, inline markup) — the typed model does not yet
        # cover every construct the transformer needs to walk.
        class SourceDocument
          METANORMA_NS = "https://www.metanorma.org/ns/standoc".freeze
          NAMESPACES = { "m" => METANORMA_NS }.freeze

          attr_reader :nokogiri

          def self.parse(input)
            case input
            when Pathname
              new(Nokogiri::XML(input.read, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS))
            when ->(x) { x.respond_to?(:read) }
              new(Nokogiri::XML(input.read, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS))
            else
              new(Nokogiri::XML(input.to_s, nil, nil, Nokogiri::XML::ParseOptions::NOBLANKS))
            end
          end

          def initialize(nokogiri)
            @nokogiri = nokogiri
          end

          def root
            nokogiri.root
          end

          def namespaces
            NAMESPACES
          end

          def bibdata
            nokogiri.at_xpath("//m:bibdata", namespaces)
          end

          def language
            node = bibdata&.at_xpath("./m:language", namespaces)
            node&.text&.strip
          end

          def docidentifier
            node = bibdata&.at_xpath("./m:docidentifier[@primary='true']", namespaces) ||
                   bibdata&.at_xpath("./m:docidentifier", namespaces)
            return nil unless node

            node.text.strip
          end

          def doctype
            node = bibdata&.at_xpath("./m:ext/m:doctype", namespaces)
            return nil unless node

            node.text.strip
          end

          def title(lang: nil, type: nil)
            xpath = "./m:title"
            constraints = []
            constraints << "@language='#{lang}'" if lang
            constraints << "@type='#{type}'" if type
            xpath += "[#{constraints.join(' and ')}]" if constraints.any?
            node = bibdata&.at_xpath(xpath, namespaces)
            return nil unless node

            node.text.strip
          end

          def edition
            node = bibdata&.at_xpath("./m:edition", namespaces)
            return nil unless node

            node.text.strip
          end

          def copyright_year
            node = bibdata&.at_xpath("./m:copyright/m:from", namespaces)
            return nil unless node

            node.text.strip
          end

          def copyright_holder
            node = bibdata&.at_xpath("./m:copyright/m:owner/m:organization/m:name", namespaces)
            return nil unless node

            node.text.strip
          end

          def publisher
            contributors = bibdata&.xpath("./m:contributor[m:role[@type='publisher']]/m:organization/m:name", namespaces)
            return nil unless contributors&.any?

            contributors.first.text.strip
          end

          def pub_date
            node = bibdata&.at_xpath("./m:date[@type='published']", namespaces) ||
                   bibdata&.at_xpath("./m:date", namespaces)
            return nil unless node

            year = node.at_xpath("./m:on", namespaces)&.text&.strip
            year || node.text.strip
          end

          def stage_code
            node = bibdata&.at_xpath("./m:status/m:stage", namespaces)
            return nil unless node

            node.text.strip
          end

          def foreword
            nokogiri.at_xpath("//m:preface/m:foreword", namespaces)
          end

          def introduction
            node = nokogiri.at_xpath("//m:preface/m:introduction", namespaces)
            return node if node

            nokogiri.at_xpath("//m:preface/m:clause[@obligation='informative' and contains(m:title, 'Introduction')]", namespaces)
          end

          def sections
            nokogiri.xpath("//m:metanorma/m:sections/m:clause", namespaces)
          end

          def annexes
            nokogiri.xpath("//m:metanorma/m:annex", namespaces)
          end

          def bibliography
            nokogiri.xpath("//m:bibliography/m:references", namespaces)
          end

          def front?
            !!foreword || !!introduction
          end

          def has_metadata?
            !!docidentifier
          end

          def has_back?
            annexes.any? || bibliography.any?
          end

          private

          # Use the metanorma-document gem's typed model to parse the source
          # XML. Returns nil if the typed parse fails (e.g. for inputs the
          # typed model does not yet cover); Nokogiri accessors above are
          # the fallback.
          def parse_typed_root
            Metanorma::OimlDocument::Root.from_xml(nokogiri.to_xml)
          rescue LoadError, StandardError
            nil
          end
        end
      end
    end
  end
end
