# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Delegates to the shared engine (metanorma-document 0.5.15,
        # Metanorma::Document::Sts::Transformer::DocumentTransformer) per
        # metanorma-iso#1760 / metanorma-document#165. The shared trunk
        # owns the reference-id pre-registration (the id-generator kinds
        # registry fills before any transform, so forward xrefs resolve
        # their ref type regardless of section order), the profile-driven
        # @dtd-version (OIML pins "1.2" on its profile), and the
        # namespace / processing-meta / lang post-processing; every
        # engine step resolves to the OIML subclasses through the
        # profile's class_overrides.
        class DocumentTransformer < Metanorma::Document::Sts::Transformer::DocumentTransformer
        end
      end
    end
  end
end
