# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class DefinitionList < Base
    def terms; Array(typed.dt); end
    def definitions; Array(typed.dd); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Lists::DefinitionList,
  Metanorma::Oiml::Sts::Source::DefinitionList
)
