# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps a Sub (SubElement) inline element.
    class Sub < Base
      def kind
        :sub
      end

      def text
        InlineExtractor.text_from(typed)
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::SubElement,
  Metanorma::Oiml::Sts::Source::Inline::Sub
)
