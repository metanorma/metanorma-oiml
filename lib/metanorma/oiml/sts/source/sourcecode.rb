# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Sourcecode < Base
    def text; InlineExtractor.text_from(typed); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::AncillaryBlocks::SourcecodeBlock,
  Metanorma::Oiml::Sts::Source::Sourcecode
)
