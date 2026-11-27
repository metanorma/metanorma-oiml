# frozen_string_literal: true

require "metanorma/oiml/sts/profile"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # The shared engine's source view, defaulting to the OIML profile.
        class SourceDocument < Metanorma::Document::Sts::Transformer::SourceDocument
          def self.parse(input, profile: Metanorma::Oiml::Sts::Profile.instance)
            super
          end

          def self.from_xml(input, profile: Metanorma::Oiml::Sts::Profile.instance)
            parse(input, profile: profile)
          end
        end
      end
    end
  end
end
