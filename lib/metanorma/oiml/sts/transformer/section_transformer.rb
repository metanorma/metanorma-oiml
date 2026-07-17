# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class SectionTransformer < Base
          def transform(source_clause, as: :sec)
            id = source_clause.id
            label_text = extract_label(source_clause)
            title_text = extract_title(source_clause)
            content = dispatcher.dispatch_section_blocks(source_clause)

            add_terms(content, source_clause)
            add_definition_lists(content, source_clause)
            add_paragraphs(content, source_clause)
            add_tables(content, source_clause)
            add_figures(content, source_clause)
            add_notes(content, source_clause)
            add_examples(content, source_clause)
            add_lists(content, source_clause)

            ModelBuilder.sec(
              id: id,
              label: label_text,
              title: title_text,
              content: content
            )
          end

          private

          def add_terms(content, source_clause)
            return unless source_clause.is_a?(Metanorma::IsoDocument::Sections::IsoTermsSection)

            Array(source_clause.term).each do |t|
              result = dispatcher.dispatch(t)
              content << result if result
            end
          end

          def add_definition_lists(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.definition_lists).each do |dl|
              result = list_transformer.transform_def_list(dl)
              content << result if result
            end
          end

          def add_paragraphs(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.paragraphs).each do |p|
              result = paragraph_transformer.transform(p)
              content << result if result
            end
          end

          def add_tables(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.tables).each do |t|
              result = table_transformer.transform(t)
              content << result if result
            end
          end

          def add_figures(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.figures).each do |f|
              result = figure_transformer.transform(f)
              content << result if result
            end
          end

          def add_notes(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.notes).each do |n|
              result = note_transformer.transform(n)
              content << result if result
            end
          end

          def add_examples(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.examples).each do |e|
              result = note_transformer.transform(e)
              content << result if result
            end
          end

          def add_lists(content, source_clause)
            return unless source_clause.is_a?(Metanorma::StandardDocument::Sections::ContentSection)

            Array(source_clause.unordered_lists).each do |ul|
              content << list_transformer.transform(ul)
            end
            Array(source_clause.ordered_lists).each do |ol|
              content << list_transformer.transform(ol)
            end
          end

          def extract_label(source_clause)
            source_clause.number
          end

          def extract_title(source_clause)
            title = source_clause.title
            return nil unless title

            # Title may contain inline elements (xref, italic, math).
            # Use RenderedTextExtractor to recover the full visible text
            # including any embedded references.
            text = ::Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor.text_of(title)
            return text unless text.nil? || text.empty?

            val = title.text
            val = Array(val).first if val.is_a?(Array)
            val.to_s.strip
          end
        end
      end
    end
  end
end
