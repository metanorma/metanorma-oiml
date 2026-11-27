# frozen_string_literal: true

# Delegates to the shared engine (metanorma-document 0.5.15, Metanorma::Document::Sts)
# per metanorma-iso#1760 / metanorma-document#165.

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ListTransformer < Metanorma::Document::Sts::Transformer::ListTransformer
          private

          # Items are cited by id from xrefs elsewhere in the document, so
          # the item keeps its source id (claimed against the document's ids)
          # for the xref rid to resolve.
          def build_list_item(source_item, ordered, fallback_marker = nil)
            item = super
            source_id = source_item.respond_to?(:id) ? source_item.id : nil
            return item if source_id.nil? || source_id.to_s.empty?

            id = id_generator.claim(source_id)
            id_generator.register(source_id, id)
            item.id = id
            item
          end
        end
      end
    end
  end
end
