# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Emits the `<back>` block: annexes inside `<app-group>`, and any
        # bibliography as `<ref-list>`.
        class BackTransformer < Base
          def transform(source, builder)
            emit_annexes(source, builder)
            emit_bibliography(source, builder)
          end

          private

          def emit_annexes(source, builder)
            return if source.annexes.empty?

            builder.app_group do
              source.annexes.each do |annex|
                section_transformer.transform(annex, builder, as: :app)
              end
            end
          end

          def emit_bibliography(source, builder)
            return if source.bibliography.empty?

            builder.ref_list("content-type" => "bibliography") do
              source.bibliography.each do |ref_section|
                emit_references_in(ref_section, builder)
              end
            end
          end

          def emit_references_in(ref_section, builder)
            ref_section.xpath("./m:bibitem", source.namespaces).each do |bibitem|
              reference_transformer.transform(bibitem, builder)
            end
          end
        end
      end
    end
  end
end
