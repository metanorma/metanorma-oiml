# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Transforms the whole Metanorma `<metanorma>` root into an OIML
        # NISO STS `<standard>` root.
        class DocumentTransformer < Base
          def transform(source)
            sts.standard("xml:lang" => context.language,
                         "xmlns:xlink" => StsXml::XLINK_NS,
                         "dtd-version" => "1.2") do
              emit_processing_meta
              sts.front { FrontTransformer.new(context).transform(source, sts) } if source.front? || source.has_metadata?
              sts.body { BodyTransformer.new(context).transform(source, sts) }
              sts.back { BackTransformer.new(context).transform(source, sts) } if source.has_back?
            end
            sts
          end

          def transform_to_xml(source)
            transform(source).to_xml
          end

          private

          def emit_processing_meta
            sts.processing_meta(
              "tagset-family" => "sts",
              "base-tagset" => "interchange",
              "table-model" => "xhtml",
              "mathml" => "MathML 3.0",
              "terminology-model" => "tbx"
            )
          end
        end
      end
    end
  end
end
