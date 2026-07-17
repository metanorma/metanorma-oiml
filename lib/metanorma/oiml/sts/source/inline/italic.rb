# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps an Italic (EmRawElement) inline element.
    class Italic < Base
      def kind
        :italic
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::EmRawElement,
  Metanorma::Oiml::Sts::Source::Inline::Italic
)
