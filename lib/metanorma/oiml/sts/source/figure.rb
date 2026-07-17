# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Figure < Base
    def label; typed.autonum; end
    def caption; typed.name ? InlineExtractor.text_from(typed.name) : nil; end
    def image; typed.image; end
    def image_source; typed.image ? typed.image.source : nil; end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::AncillaryBlocks::FigureBlock,
  Metanorma::Oiml::Sts::Source::Figure
)
