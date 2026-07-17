# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class List < Base
    def ordered?; typed.is_a?(Metanorma::Document::Components::Lists::OrderedList); end
    def list_type; ordered? ? "order" : "bullet"; end
    def items; Array(typed.listitem); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Lists::UnorderedList,
  Metanorma::Oiml::Sts::Source::List
)
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Lists::OrderedList,
  Metanorma::Oiml::Sts::Source::List
)
