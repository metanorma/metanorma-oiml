# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Admonition < Note; end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::MultiParagraph::AdmonitionBlock,
  Metanorma::Oiml::Sts::Source::Admonition
)
