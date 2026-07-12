# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Emits the `<body>` block.
        class BodyTransformer < Base
          def transform(source, builder)
            source.sections.each do |clause|
              dispatcher.dispatch(clause, builder)
            end
          end
        end
      end
    end
  end
end
