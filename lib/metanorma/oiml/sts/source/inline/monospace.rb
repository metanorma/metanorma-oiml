# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Monospace (TtElement) inline element.
    class Monospace < Base
      def kind
        :monospace
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::TtElement,
  Metanorma::Oiml::Sts::Source::Inline::Monospace
)
