# frozen_string: true

# OIML Metanorma presentation XML → OIML NISO STS XML transformer.
#
# Architecture:
# - {SourceDocument}: parses input via Metanorma::Oiml::Document::Root
#   (typed model, on the metanorma-document framework). Zero Nokogiri.
# - {Context}: shared state during one conversion run.
# - {ModelBuilder}: factory methods for sts-ruby model instances.
# - {DocumentTransformer}: orchestrator. Produces a Sts::NisoSts::Standard
#   root via sts-ruby models and serializes via lutaml-model.
# - Per-element transformers walk typed-model source objects and emit
#   sts-ruby model instances. Zero Nokogiri.
# - {RenderedTextExtractor}: unified text extraction from typed models.
# - {BlockDispatcher}: Open/Closed dispatch by typed model class name.
module Metanorma::Oiml::Sts::Transformer
  autoload :SourceDocument, "metanorma/oiml/sts/transformer/source_document"
  autoload :Context, "metanorma/oiml/sts/transformer/context"
  autoload :ModelBuilder, "metanorma/oiml/sts/transformer/model_builder"
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
  autoload :TermTransformer, "metanorma/oiml/sts/transformer/term_transformer"
  autoload :DlTransformer, "metanorma/oiml/sts/transformer/dl_transformer"
  autoload :BlockDispatcher, "metanorma/oiml/sts/transformer/block_dispatcher"
  autoload :RenderedTextExtractor, "metanorma/oiml/sts/transformer/rendered_text_extractor"

  def self.convert(input)
    source = SourceDocument.parse(input)
    context = Context.new(source)
    DocumentTransformer.new(context).transform_to_xml(source)
  end
end
