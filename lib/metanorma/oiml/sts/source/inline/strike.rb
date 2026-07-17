# frozen_string: true
module Metanorma::Oiml::Sts::Source
  module Inline
    class Strike < Base
      def kind; :strike; end
      def text; InlineExtractor.text_from(typed); end
    end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::TextElements::StrikeElement,
  Metanorma::Oiml::Sts::Source::Inline::Strike
)
