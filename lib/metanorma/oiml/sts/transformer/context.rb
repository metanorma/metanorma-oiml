# frozen_string_literal: true

require "metanorma/oiml/sts/profile"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Delegates to the shared engine (metanorma-document 0.5.15,
        # Metanorma::Document::Sts) per metanorma-iso#1760 /
        # metanorma-document#165 — defaulting the context to the OIML
        # profile so class_overrides resolve the OIML subclasses.
        class Context < Metanorma::Document::Sts::Transformer::Context
          def initialize(source, presentation_xml: nil, profile: Metanorma::Oiml::Sts::Profile.instance)
            super
          end
        end
      end
    end
  end
end
