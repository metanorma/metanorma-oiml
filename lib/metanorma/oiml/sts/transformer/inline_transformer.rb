# frozen_string_literal: true

# InlineTransformer is retained for backward compatibility but is NOT used
# in the typed-model pipeline. Inline content within paragraphs is handled
# by ParagraphTransformer via `Sts::IsoSts::Paragraph.from_xml(source.to_xml)`.
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class InlineTransformer < Base
          # No-op: inline content is handled by Paragraph.from_xml.
          # This class exists only to satisfy autoload references.
        end
      end
    end
  end
end
