# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Shared state during one conversion run. Passed to every transformer
        # so they share id mappings, footnote collection, and bibitem lookup.
        class Context
          attr_reader :source, :id_generator, :footnote_collector

          def initialize(source)
            @source = source
            @id_generator = IdGenerator.new
            @footnote_collector = FootnoteCollector.new
          end

          def language
            source.language || "en"
          end

          def docidentifier
            source.docidentifier
          end

          def bibitem_lookup
            @bibitem_lookup ||= build_bibitem_lookup
          end

          private

          def build_bibitem_lookup
            lookup = {}
            source.bibliography.each do |ref_section|
              ref_section.xpath(".//m:bibitem", source.namespaces).each do |item|
                id = item["id"]
                lookup[id] = item if id
              end
            end
            lookup
          end
        end
      end
    end
  end
end
