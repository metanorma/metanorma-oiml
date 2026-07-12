# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ListTransformer < Base
          def transform(source_node, builder)
            list_type = list_type_for(source_node)
            attrs = { list_type: list_type }
            id = source_node["id"]
            attrs[:id] = id if id

            builder.list(**attrs) do
              source_node.xpath("./m:li", source.namespaces).each do |li|
                emit_list_item(li, builder)
              end
            end
          end

          private

          def emit_list_item(li_node, builder)
            builder.list_item do
              inline_transformer.transform_children(li_node, builder)
            end
          end

          def list_type_for(node)
            case node.name
            when "ul" then "bullet"
            when "ol" then "order"
            else "bullet"
            end
          end
        end
      end
    end
  end
end
