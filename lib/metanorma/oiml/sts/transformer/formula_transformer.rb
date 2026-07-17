# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FormulaTransformer < Base
          def transform(source_formula)
            attrs = {}
            attrs[:id] = source_formula.id if source_formula.id
            ::Sts::IsoSts::DispFormula.new(attrs)
          end
        end
      end
    end
  end
end
