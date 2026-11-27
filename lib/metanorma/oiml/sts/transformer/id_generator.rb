# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # OIML id policy on top of the shared engine (metanorma-document
        # 0.5.15): terms stay ordinary sections with their source ids, claims
        # stay unique even against explicitly requested suffixes, and an
        # anonymous annex keeps one identity across lookups.
        class IdGenerator < Metanorma::Document::Sts::Transformer::IdGenerator
          # An emitted id resolves to the same kind as its source id.
          def register(source_id, sts_id, kind = nil)
            super
            @kinds[sts_id] = kind if kind
          end

          # Document-unique variant of +base+: a collision appends _1, _2, ...
          # until the candidate is free, so a requested suffix never repeats.
          def claim(base)
            return nil unless base

            candidate = base
            suffix = 0
            while @issued_ids.key?(candidate)
              suffix += 1
              candidate = "#{base}_#{suffix}"
            end
            @issued_ids[candidate] = true
            candidate
          end

          # Annex ids allocate their letter only when the annex is new.
          def id_for_annex(annex, autonum)
            registered_or_claim(annex, "annex") do
              if autonum
                claim("sec_#{autonum}")
              else
                letter = alpha_suffix(@annex_count, "A")
                @annex_count += 1
                claim("sec_#{letter}")
              end
            end
          end

          # OIML terms remain ordinary sections with their source ids.
          def term_ids(term)
            id_for_clause(term)
          end

          # Tables are cited by id from anywhere in the body; mark their kind
          # in the pre-registration pass so a forward xref resolves to
          # ref-type "table".
          def pre_register(source)
            super
            mark_tables(source.typed_root)
            self
          end

          private

          def mark_tables(node, seen = {}.compare_by_identity)
            return unless node.is_a?(Lutaml::Model::Serializable)
            return if seen.key?(node)

            seen[node] = true
            mark_kind(node.id, "table") if node.class.name&.split("::")&.last == "TableBlock" && node.id
            node.class.attributes.each_key do |attr|
              value = begin
                node.public_send(attr)
              rescue StandardError
                next
              end
              Array(value).each { |child| mark_tables(child, seen) }
            end
          end

          def registered_or_claim(element, kind = nil, &block)
            source_id = read_id(element) || "object:#{element.object_id}"
            if @registry.key?(source_id)
              @registry[source_id]
            else
              id = block.call
              register(source_id, id, kind)
              id
            end
          end
        end
      end
    end
  end
end
