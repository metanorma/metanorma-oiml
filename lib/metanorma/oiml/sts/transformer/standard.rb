# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Adapter conforming to the metanorma-core
        # +Processor#document_transformers+ contract: +.new(model, options)+,
        # where +model+ is the reader's parse result
        # (+Metanorma::Oiml::Document::Root+); +#transform+ returns a target
        # responding to +#to_xml+.
        #
        # Delegates to the shared engine (metanorma-document 0.5.15,
        # Metanorma::Document::Sts::Transformer::Standard) per
        # metanorma-iso#1760 / metanorma-document#165: the shared adapter
        # normalizes the driver's raw Root into the source wrapper and
        # resolves the sibling presentation XML — options
        # [:sts_presentation_xml], or the +document.presentation.xml+
        # sibling of options[:sourcefilename] — that the requirement
        # blocks prefer for their rendered provision tables. The context
        # resolves every engine step to the OIML subclasses through this
        # profile's class_overrides.
        class Standard < Metanorma::Document::Sts::Transformer::Standard
          # ---- Profile hook (public extension point) -----------------

          # The OIML publisher profile driving this adapter.
          def profile
            Metanorma::Oiml::Sts::Profile.instance
          end
        end
      end
    end
  end
end
