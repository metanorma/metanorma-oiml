# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Dispatches a typed source model object (from metanorma-document)
        # to the right per-element transformer and RETURNS the resulting
        # sts-ruby model instance.
        #
        # Dispatch is by CLASS, not by XML element name (no Nokogiri).
        class BlockDispatcher < Base
          HANDLERS = {
            "ClauseSection"             => :dispatch_via_section,
            "IsoClauseSection"          => :dispatch_via_section,
            "ClauseHierarchicalSection" => :dispatch_via_section,
            "IsoAnnexSection"           => :dispatch_via_section,
            "AnnexSection"              => :dispatch_via_section,
            "IsoForewordSection"        => :dispatch_via_section,
            "Foreword"                  => :dispatch_via_section,
            "Introduction"              => :dispatch_via_section,
            "IsoIntroductionSection"    => :dispatch_via_section,
            "IsoTermsSection"           => :dispatch_via_section,
            "TermsSection"              => :dispatch_via_section,
            "DefinitionSection"         => :dispatch_via_section,
            "IsoTerm"                   => :dispatch_via_term,
            "Term"                      => :dispatch_via_term,
            "ParagraphBlock"            => :dispatch_via_paragraph,
            "ParagraphWithFootnote"     => :dispatch_via_paragraph,
            "UnorderedList"             => :dispatch_via_list,
            "OrderedList"               => :dispatch_via_list,
            "DefinitionList"            => :dispatch_via_def_list,
            "TableBlock"                => :dispatch_via_table,
            "FigureBlock"               => :dispatch_via_figure,
            "FormulaBlock"              => :dispatch_via_formula,
            "NoteBlock"                 => :dispatch_via_note,
            "ExampleBlock"              => :dispatch_via_note,
            "AdmonitionBlock"           => :dispatch_via_note,
            "QuoteBlock"                => :dispatch_via_note,
            "SourcecodeBlock"           => :dispatch_via_preformat,
            "StandardReferencesSection" => :dispatch_via_references,
            "BibliographySection"       => :dispatch_via_references
          }.freeze

          # Presentation/formatting element classes that are duplicates of
          # semantic content. We never dispatch these.
          PRESENTATION_CLASSES = %w[
            FmtTitleElement
            FmtXrefLabelElement
            FmtNameElement
            FmtStemElement
            FmtFnLabelElement
            FmtAnnotationStartElement
            FmtAnnotationEndElement
            FmtConceptElement
            SemxElement
            LocalizedString
            LocalizedStrings
            FmtVal
            AsciiMath
          ].freeze

          def dispatch(source_obj)
            return nil unless source_obj
            return nil if source_obj.is_a?(String)

            class_name = source_obj.class.name&.split("::")&.last
            return nil if PRESENTATION_CLASSES.include?(class_name)

            handler = HANDLERS[class_name]
            return nil unless handler

            send(handler, source_obj)
          end

          # Walk a section's content in document order via
          # `each_mixed_content`, which every typed model Serializable
          # supports. Filter out strings and presentation duplicates.
          def dispatch_section_blocks(section)
            results = []
            section.each_mixed_content do |node|
              next if node.is_a?(String)
              result = dispatch(node)
              results << result if result
            end
            results
          end

          private

          def dispatch_via_section(obj);   section_transformer.transform(obj);   end
          def dispatch_via_paragraph(obj); paragraph_transformer.transform(obj); end
          def dispatch_via_list(obj);     list_transformer.transform(obj);     end
          def dispatch_via_def_list(obj); list_transformer.transform_def_list(obj); end
          def dispatch_via_table(obj);    table_transformer.transform(obj);    end
          def dispatch_via_figure(obj);   figure_transformer.transform(obj);   end
          def dispatch_via_formula(obj);  formula_transformer.transform(obj);  end
          def dispatch_via_note(obj);     note_transformer.transform(obj);     end
          def dispatch_via_preformat(obj); note_transformer.transform_preformat(obj); end
          def dispatch_via_term(obj);     term_transformer.transform(obj);     end
          def dispatch_via_references(obj); reference_transformer.transform_section(obj); end
        end
      end
    end
  end
end
