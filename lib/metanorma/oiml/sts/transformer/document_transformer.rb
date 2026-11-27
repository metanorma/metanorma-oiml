# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # The shared engine does the work; OIML adds only its NBSP typography
        # (dtd-version and processing-meta come from the OIML profile).
        class DocumentTransformer < Metanorma::Document::Sts::Transformer::DocumentTransformer
          def apply_nbsp(xml)
            NbspProcessor.apply_to_text(xml)
          end
        end
      end
    end
  end
end
