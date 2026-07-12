# frozen_string_literal: true

# OIML Metanorma presentation XML → OIML NISO STS XML transformer.
#
# Architecture (mirrors `Metanorma::Iso::Sts::Transformer` from the
# `metanorma-iso` gem):
#
# - {SourceDocument}: parsed-input façade that uses
#   `Metanorma::OimlDocument::Root` (from the `metanorma-document` gem) for
#   typed parsing, with Nokogiri fallbacks for elements the typed model
#   does not yet cover.
# - {Context}: shared state during one conversion run.
# - {StsXml}: Nokogiri-backed output builder.
# - {DocumentTransformer}: orchestrator. Produces the `<standard>` root.
# - {FrontTransformer}, {BodyTransformer}, {BackTransformer}: section-level
#   orchestrators.
# - Per-element transformers for individual Metanorma elements.
#
# Adding a new element = adding one transformer class and registering it
# with {BlockDispatcher} (Open/Closed at the dispatch level).
module Metanorma::Oiml::Sts::Transformer
  autoload :SourceDocument, "metanorma/oiml/sts/transformer/source_document"
  autoload :Context, "metanorma/oiml/sts/transformer/context"
  autoload :StsXml, "metanorma/oiml/sts/transformer/sts_xml"
  autoload :IdGenerator, "metanorma/oiml/sts/transformer/id_generator"
  autoload :FootnoteCollector, "metanorma/oiml/sts/transformer/footnote_collector"
  autoload :Base, "metanorma/oiml/sts/transformer/base"
  autoload :DocumentTransformer, "metanorma/oiml/sts/transformer/document_transformer"
  autoload :FrontTransformer, "metanorma/oiml/sts/transformer/front_transformer"
  autoload :BodyTransformer, "metanorma/oiml/sts/transformer/body_transformer"
  autoload :BackTransformer, "metanorma/oiml/sts/transformer/back_transformer"
  autoload :SectionTransformer, "metanorma/oiml/sts/transformer/section_transformer"
  autoload :ParagraphTransformer, "metanorma/oiml/sts/transformer/paragraph_transformer"
  autoload :InlineTransformer, "metanorma/oiml/sts/transformer/inline_transformer"
  autoload :ListTransformer, "metanorma/oiml/sts/transformer/list_transformer"
  autoload :TableTransformer, "metanorma/oiml/sts/transformer/table_transformer"
  autoload :FigureTransformer, "metanorma/oiml/sts/transformer/figure_transformer"
  autoload :FormulaTransformer, "metanorma/oiml/sts/transformer/formula_transformer"
  autoload :NoteTransformer, "metanorma/oiml/sts/transformer/note_transformer"
  autoload :ReferenceTransformer, "metanorma/oiml/sts/transformer/reference_transformer"
  autoload :BlockDispatcher, "metanorma/oiml/sts/transformer/block_dispatcher"

  # Convert a Metanorma presentation XML input into OIML NISO STS XML.
  # @param input [String, Pathname, #read] the source XML.
  # @return [String] OIML NISO STS XML.
  def self.convert(input)
    source = SourceDocument.parse(input)
    context = Context.new(source)
    DocumentTransformer.new(context).transform_to_xml(source)
  end
end
