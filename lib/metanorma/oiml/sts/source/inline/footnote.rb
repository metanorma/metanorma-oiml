# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Footnote (FnElement) inline element.
    class Footnote < Base
      def kind
        :fn
      end

      def id
        typed.id || typed.reference
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::FnElement,
  Metanorma::Oiml::Sts::Source::Inline::Footnote
)
