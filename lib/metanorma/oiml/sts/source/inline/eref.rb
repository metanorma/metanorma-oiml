# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps an Eref (ErefElement) inline element.
    class Eref < Base
      def kind
        :xref
      end

      def target
        typed.target
      end

      def citeas
        typed.citeas
      end

      def text
        citeas || typed.target || ""
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::ErefElement,
  Metanorma::Oiml::Sts::Source::Inline::Eref
)
