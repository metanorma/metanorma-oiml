# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # The metanorma-core +Processor#document_transformers+ adapter of the
        # shared engine, bound to the OIML profile (structure hooks, the
        # sibling presentation XML for requirement tables, OIML post-steps).
        class Standard < Metanorma::Document::Sts::Transformer::Standard
          def profile
            Metanorma::Oiml::Sts::Profile.instance
          end

          private

          # The adapter hands the engine the raw reader result; wrap it
          # with the OIML source view so the OIML profile reads it.
          def source
            return @model if @model.is_a?(Metanorma::Document::Sts::Transformer::SourceDocument)

            SourceDocument.new(@model, profile: profile)
          end
        end
      end
    end
  end
end
