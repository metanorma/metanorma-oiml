# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Generates stable, deterministic `@id` values for OIML STS
        # elements from typed source models. No Nokogiri, no XPath.
        class IdGenerator
          def initialize
            @registry = {}
            @counter = 0
          end

          def register(source_id, sts_id)
            @registry[source_id] = sts_id
          end

          def remap(source_id)
            @registry[source_id]
          end

          # Returns the id for a typed model object. Uses the source
          # model's `id` when present (verbatim); otherwise derives a
          # slug from `title`/`name` text, or falls back to a numbered id.
          def id_for(source_obj, prefix: "sec")
            return nil unless source_obj

            source_id = source_obj.respond_to?(:id) ? source_obj.id : nil
            if source_id && !source_id.empty?
              registered = @registry[source_id]
              return registered if registered

              register(source_id, source_id)
              return source_id
            end

            generate(source_obj, prefix)
          end

          private

          def generate(source_obj, prefix)
            slug = slug_from(source_obj)
            slug ? "#{prefix}_#{slug}" : next_anonymous(prefix)
          end

          def slug_from(source_obj)
            title = title_text_of(source_obj)
            return nil if title.nil? || title.empty?

            slug = title.downcase.gsub(/[^a-z0-9]+/, "_").gsub(/\A_|_\z/, "").slice(0, 40)
            slug.empty? ? nil : slug
          end

          # Pulls visible text from a typed model that may expose its
          # title via `title`, `name`, or `text` (each_mixed_content
          # aware). Returns "" if none yield text.
          def title_text_of(source_obj)
            %i[title name text].each do |attr|
              next unless source_obj.respond_to?(attr)
              val = source_obj.public_send(attr)
              txt = flatten_to_string(val)
              return txt if txt && !txt.empty?
            end
            ""
          end

          def flatten_to_string(val)
            return val.to_s if val.is_a?(String)
            return "" unless val

            if val.respond_to?(:each_mixed_content)
              parts = []
              val.each_mixed_content { |n| parts << n if n.is_a?(String) }
              return parts.join.strip
            end

            Array(val).map(&:to_s).join.strip
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
