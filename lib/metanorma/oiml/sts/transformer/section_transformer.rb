# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Transforms a Metanorma `<clause>` or `<annex>` into a NISO STS
        # `<sec>` or `<app>`.
        class SectionTransformer < Base
          def transform(source_node, builder, as: :sec)
            id = context.id_generator.id_for(source_node, prefix: tag_prefix(as))
            builder.public_send(tag_name(as), id ? { id: id } : {}) do
              emit_label_and_title(source_node, builder)
              emit_children(source_node, builder)
            end
          end

          private

          def tag_name(as)
            as == :app ? :app : :sec
          end

          def tag_prefix(as)
            as == :app ? "app" : "sec"
          end

          def emit_label_and_title(source_node, builder)
            label = source_node.at_xpath("./m:fmt-name/m:tab | ./m:name/m:tab", source.namespaces)
            title_node = source_node.at_xpath("./m:fmt-title | ./m:title", source.namespaces)
            title_text = extract_title_text(title_node)

            builder.label(label.text.strip) if label && !label.text.strip.empty?
            builder.title(title_text) if title_text && !title_text.empty?
          end

          def extract_title_text(title_node)
            return nil unless title_node

            title_node.children.reject { |c| c.name == "tab" }.map(&:text).join.strip
          end

          def emit_children(source_node, builder)
            source_node.element_children.each do |child|
              next if structural_name?(child.name)

              dispatcher.dispatch(child, builder)
            end
          end

          def structural_name?(name)
            %w[fmt-title title fmt-name name].include?(name)
          end
        end
      end
    end
  end
end
