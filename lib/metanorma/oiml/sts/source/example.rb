# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Example < Note; end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::AncillaryBlocks::ExampleBlock,
  Metanorma::Oiml::Sts::Source::Example
)
