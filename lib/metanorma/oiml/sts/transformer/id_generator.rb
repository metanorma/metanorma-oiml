# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Generates stable, deterministic `@id` values for OIML STS elements.
        class IdGenerator
          def initialize
            @registry = {}
            @counter = 0
          end

          def remap(source_id)
            @registry[source_id]
          end

          def register(source_id, sts_id)
            @registry[source_id] = sts_id
          end

          def id_for(source_node, prefix: "sec")
            return nil unless source_node

            source_id = source_node["id"]
            return @registry[source_id] if source_id && @registry[source_id]

            generated = generate(source_node, prefix)
            register(source_id, generated) if source_id
            generated
          end

          private

          def generate(source_node, prefix)
            slug = slug_from(source_node)
            slug ? "#{prefix}_#{slug}" : next_anonymous(prefix)
          end

          def slug_from(source_node)
            title = source_node.at_xpath(".//m:title", SourceDocument::NAMESPACES)&.text&.strip
            return nil unless title

            title.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "").slice(0, 40)
          end

          def next_anonymous(prefix)
            @counter += 1
            "#{prefix}_#{@counter}"
          end
        end
      end
    end
  end
end
