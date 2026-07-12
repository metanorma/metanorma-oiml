# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ParagraphTransformer < Base
          def transform(source_node, builder)
            id = source_node["id"]
            attrs = {}
            attrs[:id] = id if id

            builder.p(attrs) do
              inline_transformer.transform_children(source_node, builder)
            end
          end
        end
      end
    end
  end
end
