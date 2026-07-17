# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class ListItem < Base
    def paragraphs; Array(typed.paragraphs); end
    def unordered_lists; Array(typed.unordered_lists); end
    def ordered_lists; Array(typed.ordered_lists); end
    def text; InlineExtractor.text_from(typed); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Lists::ListItem,
  Metanorma::Oiml::Sts::Source::ListItem
)
