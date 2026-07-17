# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Quote < Note; end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::MultiParagraph::QuoteBlock,
  Metanorma::Oiml::Sts::Source::Quote
)
