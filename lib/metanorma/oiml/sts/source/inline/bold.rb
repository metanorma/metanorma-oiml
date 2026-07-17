# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Bold (StrongRawElement) inline element.
    class Bold < Base
      def kind
        :bold
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::StrongRawElement,
  Metanorma::Oiml::Sts::Source::Inline::Bold
)
