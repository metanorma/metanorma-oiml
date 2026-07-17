# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Note < Base
    def paragraphs; Array(typed.content); end
    def text; paragraphs.map { |p| InlineExtractor.text_from(p) }.join(" "); end
  end
end
