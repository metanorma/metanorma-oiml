# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FormulaTransformer < Base
          def transform(source_node, builder)
            id = context.id_generator.id_for(source_node, prefix: "for")
            builder.disp_formula(id: id) do
              emit_label(source_node, builder)
              emit_math(source_node, builder)
            end
          end

          private

          def emit_label(source_node, builder)
            name_node = source_node.at_xpath("./m:fmt-name/m:tab | ./m:name/m:tab", source.namespaces)
            text = name_node&.text&.strip
            builder.label(text) if text && !text.empty?
          end

          def emit_math(source_node, builder)
            math = source_node.at_xpath(".//m:math", source.namespaces)
            return unless math

            cloned = math.clone
            cloned.add_namespace("mml", StsXml::MML_NS)
            builder.document.root << cloned
          end
        end
      end
    end
  end
end
