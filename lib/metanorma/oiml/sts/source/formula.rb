# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Formula < Base
    def text; InlineExtractor.text_from(typed); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::AncillaryBlocks::FormulaBlock,
  Metanorma::Oiml::Sts::Source::Formula
)
