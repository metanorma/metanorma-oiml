# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Table < Base
    def thead; typed.thead; end
    def tbody; typed.tbody; end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Tables::TableBlock,
  Metanorma::Oiml::Sts::Source::Table
)
