# frozen_string: true
module Metanorma::Oiml::Sts::Source
  module Inline
    class Underline < Base
      def kind; :underline; end
      def text; InlineExtractor.text_from(typed); end
    end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::TextElements::UnderlineElement,
  Metanorma::Oiml::Sts::Source::Inline::Underline
)
