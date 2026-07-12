# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class NoteTransformer < Base
          TAG_MAP = {
            "note"    => "non-normative-note",
            "example" => "non-normative-example",
            "quote"   => "disp-quote"
          }.freeze

          def transform(source_node, builder)
            tag = TAG_MAP[source_node.name]
            return unless tag

            id = source_node["id"]
            attrs = {}
            attrs[:id] = id if id

            builder.public_send(tag, attrs) do
              inline_transformer.transform_children(source_node, builder)
            end
          end
        end
      end
    end
  end
end
