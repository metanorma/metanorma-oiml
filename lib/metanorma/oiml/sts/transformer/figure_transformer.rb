# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FigureTransformer < Base
          def transform(source_node, builder)
            id = context.id_generator.id_for(source_node, prefix: "fig")
            builder.fig(id: id) do
              emit_label(source_node, builder)
              emit_caption(source_node, builder)
              emit_graphic(source_node, builder)
              emit_alt_text(source_node, builder)
            end
          end

          private

          def emit_label(source_node, builder)
            name_node = source_node.at_xpath("./m:fmt-name/m:tab | ./m:name/m:tab", source.namespaces)
            text = name_node&.text&.strip
            builder.label(text) if text && !text.empty?
          end

          def emit_caption(source_node, builder)
            title_node = source_node.at_xpath("./m:fmt-name | ./m:name | ./m:fmt-title | ./m:title", source.namespaces)
            return unless title_node

            text = title_node.children.reject { |c| c.name == "tab" }.map(&:text).join.strip
            return if text.empty?

            builder.caption { builder.text(text) }
          end

          def emit_graphic(source_node, builder)
            image = source_node.at_xpath(".//m:image", source.namespaces)
            return unless image

            href = image["src"] || image["href"]
            return unless href

            builder.graphic("xmlns:xlink" => StsXml::XLINK_NS, "xlink:href" => href)
          end

          def emit_alt_text(source_node, builder)
            image = source_node.at_xpath(".//m:image", source.namespaces)
            alt = image && image["alttext"]
            return unless alt && !alt.empty?

            builder.alt_text(alt)
          end
        end
      end
    end
  end
end
