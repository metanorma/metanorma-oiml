# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Boilerplate < Base
    def copyright_statements; Array(typed.copyright_statement); end
    def each_copyright_paragraph
      return enum_for(:each_copyright_paragraph) unless block_given?
      copyright_statements.each do |cs|
        cs.each_mixed_content do |inner|
          next if inner.is_a?(String)
          next unless inner.is_a?(Metanorma::StandardDocument::Sections::ContentSection)
          Array(inner.paragraphs).each { |p| yield p }
        end
      end
    end
  end
end
