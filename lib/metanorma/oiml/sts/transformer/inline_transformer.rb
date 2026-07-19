# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class InlineTransformer < Base
          def transform(source_node)
            paragraph_transformer.transform(source_node)
          end
        end
      end
    end
  end
end
