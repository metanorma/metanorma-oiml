# frozen_string_literal: true

# Source model adapters that wrap the typed `Metanorma::Document::*`
# objects behind a stable, typed interface. Every adapter exposes
# deterministic methods — never `respond_to?`, `instance_variable_get`,
# or `rescue nil` chains.
module Metanorma::Oiml::Sts::Source
  autoload :InlineExtractor, "metanorma/oiml/sts/source/inline_extractor"
  autoload :Base, "metanorma/oiml/sts/source/base"
  autoload :Registry, "metanorma/oiml/sts/source/registry"
  autoload :Section, "metanorma/oiml/sts/source/section"
  autoload :Paragraph, "metanorma/oiml/sts/source/paragraph"
  autoload :List, "metanorma/oiml/sts/source/list"
  autoload :ListItem, "metanorma/oiml/sts/source/list_item"
  autoload :Table, "metanorma/oiml/sts/source/table"
  autoload :TableCell, "metanorma/oiml/sts/source/table_cell"
  autoload :Figure, "metanorma/oiml/sts/source/figure"
  autoload :Formula, "metanorma/oiml/sts/source/formula"
  autoload :Note, "metanorma/oiml/sts/source/note"
  autoload :Example, "metanorma/oiml/sts/source/example"
  autoload :Quote, "metanorma/oiml/sts/source/quote"
  autoload :Sourcecode, "metanorma/oiml/sts/source/sourcecode"
  autoload :Admonition, "metanorma/oiml/sts/source/admonition"
  autoload :DefinitionList, "metanorma/oiml/sts/source/definition_list"
  autoload :Term, "metanorma/oiml/sts/source/term"
  autoload :BibliographicItem, "metanorma/oiml/sts/source/bibliographic_item"
  autoload :Boilerplate, "metanorma/oiml/sts/source/boilerplate"
  autoload :Document, "metanorma/oiml/sts/source/document"

  module Inline
    autoload :Text, "metanorma/oiml/sts/source/inline/text"
    autoload :Bold, "metanorma/oiml/sts/source/inline/bold"
    autoload :Italic, "metanorma/oiml/sts/source/inline/italic"
    autoload :Sub, "metanorma/oiml/sts/source/inline/sub"
    autoload :Sup, "metanorma/oiml/sts/source/inline/sup"
    autoload :Monospace, "metanorma/oiml/sts/source/inline/monospace"
    autoload :Underline, "metanorma/oiml/sts/source/inline/underline"
    autoload :Strike, "metanorma/oiml/sts/source/inline/strike"
    autoload :Link, "metanorma/oiml/sts/source/inline/link"
    autoload :Xref, "metanorma/oiml/sts/source/inline/xref"
    autoload :Eref, "metanorma/oiml/sts/source/inline/eref"
    autoload :Footnote, "metanorma/oiml/sts/source/inline/footnote"
    autoload :Stem, "metanorma/oiml/sts/source/inline/stem"
    autoload :Note, "metanorma/oiml/sts/source/inline/note"
  end

  # Factory: wrap any typed-model object in the correct adapter.
  def self.wrap(typed)
    return nil if typed.nil?
    return typed if typed.is_a?(Base)

    adapter = Registry.adapter_for(typed.class)
    adapter ? adapter.new(typed) : nil
  end

  # Factory: wrap an array of typed-model objects.
  def self.wrap_all(typed_array)
    Array(typed_array).map { |t| wrap(t) }.compact
  end
end
