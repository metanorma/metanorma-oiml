# frozen_string_literal: true

require "metanorma/oiml/document"

module Metanorma
  module Oiml
    module Sts
      # The OIML publisher profile for the shared STS engine
      # (metanorma-document 0.5.15, Metanorma::Document::Sts) —
      # metanorma-iso#1760 / metanorma-document#165.
      class Profile
        def self.instance
          @instance ||= Metanorma::Document::Sts::Profile.new(
            name: :oiml,
            org_abbrev: "OIML",
            reader_class: Metanorma::Oiml::Document::Root,
            validator_class: Metanorma::Oiml::Sts::Validator,
            class_overrides: overrides,
          ).freeze.tap { |p| Metanorma::Document::Sts::Profiles.register(p) }
        end

        # Built lazily: the OIML subclasses load via autoload after this
        # file, so the constant references resolve on first use.
        def self.overrides
          {
            Metanorma::Document::Sts::HtmlRenderer::Ruby => Metanorma::Oiml::Sts::HtmlRenderer::Ruby,
            Metanorma::Document::Sts::ParityValidator::Normaliser => Metanorma::Oiml::Sts::ParityValidator::Normaliser,
            Metanorma::Document::Sts::ParityValidator::Report => Metanorma::Oiml::Sts::ParityValidator::Report,
            Metanorma::Document::Sts::Transformer::BackTransformer => Metanorma::Oiml::Sts::Transformer::BackTransformer,
            Metanorma::Document::Sts::Transformer::Base => Metanorma::Oiml::Sts::Transformer::Base,
            Metanorma::Document::Sts::Transformer::BlockDispatcher => Metanorma::Oiml::Sts::Transformer::BlockDispatcher,
            Metanorma::Document::Sts::Transformer::BodyTransformer => Metanorma::Oiml::Sts::Transformer::BodyTransformer,
            Metanorma::Document::Sts::Transformer::DlTransformer => Metanorma::Oiml::Sts::Transformer::DlTransformer,
            Metanorma::Document::Sts::Transformer::DocumentTransformer => Metanorma::Oiml::Sts::Transformer::DocumentTransformer,
            Metanorma::Document::Sts::Transformer::FigureTransformer => Metanorma::Oiml::Sts::Transformer::FigureTransformer,
            Metanorma::Document::Sts::Transformer::FootnoteCollector => Metanorma::Oiml::Sts::Transformer::FootnoteCollector,
            Metanorma::Document::Sts::Transformer::FormulaTransformer => Metanorma::Oiml::Sts::Transformer::FormulaTransformer,
            Metanorma::Document::Sts::Transformer::FrontTransformer => Metanorma::Oiml::Sts::Transformer::FrontTransformer,
            Metanorma::Document::Sts::Transformer::IdGenerator => Metanorma::Oiml::Sts::Transformer::IdGenerator,
            Metanorma::Document::Sts::Transformer::InlineTransformer => Metanorma::Oiml::Sts::Transformer::InlineTransformer,
            Metanorma::Document::Sts::Transformer::ListTransformer => Metanorma::Oiml::Sts::Transformer::ListTransformer,
            Metanorma::Document::Sts::Transformer::NoteTransformer => Metanorma::Oiml::Sts::Transformer::NoteTransformer,
            Metanorma::Document::Sts::Transformer::ParagraphTransformer => Metanorma::Oiml::Sts::Transformer::ParagraphTransformer,
            Metanorma::Document::Sts::Transformer::ReferenceTransformer => Metanorma::Oiml::Sts::Transformer::ReferenceTransformer,
            Metanorma::Document::Sts::Transformer::RenderedTextExtractor => Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor,
            Metanorma::Document::Sts::Transformer::SectionTransformer => Metanorma::Oiml::Sts::Transformer::SectionTransformer,
            Metanorma::Document::Sts::Transformer::Standard => Metanorma::Oiml::Sts::Transformer::Standard,
            Metanorma::Document::Sts::Transformer::TableTransformer => Metanorma::Oiml::Sts::Transformer::TableTransformer,
            Metanorma::Document::Sts::Transformer::TermTransformer => Metanorma::Oiml::Sts::Transformer::TermTransformer,
            Metanorma::Document::Sts::ValidationReport => Metanorma::Oiml::Sts::ValidationReport,
            Metanorma::Document::Sts::Validator => Metanorma::Oiml::Sts::Validator,
          }
        end
      end
    end
  end
end
