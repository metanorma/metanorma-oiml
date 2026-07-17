# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Sup (SupElement) inline element.
    class Sup < Base
      def kind
        :sup
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::SupElement,
  Metanorma::Oiml::Sts::Source::Inline::Sup
)
