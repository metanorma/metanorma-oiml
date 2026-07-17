# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class TableCell < Base
    def each_inline
      return enum_for(:each_inline) unless block_given?
      typed.each_mixed_content { |n| yield n }
    end
    def text_strings; Array(typed.text); end
    def bolds; Array(typed.strong); end
    def italics; Array(typed.em); end
    def stems; Array(typed.stem); end
    def align; typed.align; end
    def valign; typed.valign; end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Tables::TextTableCell,
  Metanorma::Oiml::Sts::Source::TableCell
)
