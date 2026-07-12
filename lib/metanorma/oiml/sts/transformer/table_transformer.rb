# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class TableTransformer < Base
          def transform(source_node, builder)
            id = context.id_generator.id_for(source_node, prefix: "tab")
            builder.table_wrap(id: id) do
              emit_caption(source_node, builder)
              emit_table(source_node, builder)
            end
          end

          private

          def emit_caption(source_node, builder)
            title_node = source_node.at_xpath("./m:fmt-name | ./m:name", source.namespaces)
            return unless title_node

            text = title_node.text.strip
            return if text.empty?

            builder.caption { builder.text(text) }
          end

          def emit_table(source_node, builder)
            builder.table do
              source_node.xpath("./m:tbody/m:tr | ./m:tr", source.namespaces).each do |tr|
                emit_row(tr, builder)
              end
            end
          end

          def emit_row(tr_node, builder)
            builder.tr do
              tr_node.xpath("./m:td | ./m:th", source.namespaces).each do |cell|
                tag = cell.name == "th" ? :th : :td
                builder.public_send(tag) do
                  inline_transformer.transform_children(cell, builder)
                end
              end
            end
          end
        end
      end
    end
  end
end
