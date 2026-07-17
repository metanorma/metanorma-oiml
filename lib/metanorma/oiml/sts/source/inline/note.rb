# frozen_string: true
module Metanorma::Oiml::Sts::Source
  module Inline
    class Note < Base
      def kind; :note; end
      def paragraphs; Array(typed.content); end
      def text; paragraphs.map { |p| InlineExtractor.text_from(p) }.join(" "); end
    end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Blocks::NoteBlock,
  Metanorma::Oiml::Sts::Source::Inline::Note
)
