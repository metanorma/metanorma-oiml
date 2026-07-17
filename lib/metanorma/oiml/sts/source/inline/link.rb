# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Link (LinkElement) inline element.
    class Link < Base
      def kind
        :link
      end

      def href
        typed.target || typed.href
      end

      def text
        InlineExtractor.text_from(typed)
      end

      # For mailto: links, use the email address as visible text.
      def visible_text
        h = href
        return h.sub(/\Amailto:/, "") if h && h.start_with?("mailto:")

        text
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::LinkElement,
  Metanorma::Oiml::Sts::Source::Inline::Link
)
