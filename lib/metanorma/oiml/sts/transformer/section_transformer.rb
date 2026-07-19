# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class SectionTransformer < Base
          def transform(source_clause)
            title_text = extract_title(source_clause)
            id_val = source_clause.id if source_clause.is_a?(Lutaml::Model::Serializable) && source_clause.class.method_defined?(:id) && source_clause.id

            content = dispatcher.dispatch_section_blocks(source_clause)

            # Dispatch nested clauses for any section type carrying a
            # clause collection (IsoClauseSection AND IsoAnnexSection —
            # annex subsections like the Examples annex's entries).
            nested_clauses = []
            if source_clause.is_a?(Lutaml::Model::Serializable) && source_clause.class.method_defined?(:clause)
              nested_clauses = Array(source_clause.clause).map { |sub| transform(sub) }.compact
            end

            # Dispatch terms sections (IsoTermsSection has .term collection)
            if source_clause.is_a?(Metanorma::IsoDocument::Sections::IsoClauseSection) && source_clause.class.method_defined?(:terms)
              Array(source_clause.terms).each do |terms_section|
                Array(terms_section.term).each do |term|
                  term_sec = term_transformer.transform(term)
                  nested_clauses << term_sec if term_sec
                end
              end
            end

            attrs = {}
            attrs[:id] = id_val if id_val
            attrs[:title] = ::Sts::IsoSts::Title.new(content: [title_text]) if title_text && !title_text.empty?

            paragraphs, lists, figs, tables, notes, examples, formulas, def_lists, sub_secs = [], [], [], [], [], [], [], [], []
            content.each do |item|
              case item
              when ::Sts::IsoSts::Paragraph then paragraphs << item
              when ::Sts::IsoSts::List then lists << item
              when ::Sts::IsoSts::Fig then figs << item
              when ::Sts::TbxIsoTml::TableWrap then tables << item
              when ::Sts::IsoSts::NonNormativeNote then notes << item
              when ::Sts::IsoSts::NonNormativeExample then examples << item
              when ::Sts::IsoSts::DispFormula then formulas << item
              when ::Sts::IsoSts::DefList then def_lists << item
              when ::Sts::IsoSts::Sec then sub_secs << item
              end
            end
            nested_clauses.concat(sub_secs)

            attrs[:paragraph] = paragraphs if paragraphs.any?
            attrs[:list] = lists if lists.any?
            attrs[:fig] = figs if figs.any?
            attrs[:table_wrap] = tables if tables.any?
            attrs[:non_normative_note] = notes if notes.any?
            attrs[:non_normative_example] = examples if examples.any?
            attrs[:disp_formula] = formulas if formulas.any?
            attrs[:def_list] = def_lists if def_lists.any?
            attrs[:sec] = nested_clauses if nested_clauses.any?

            ::Sts::IsoSts::Sec.new(attrs)
          end

          private

          def extract_title(source_clause)
            return nil unless source_clause.class.method_defined?(:title) && source_clause.title
            RenderedTextExtractor.text_of(source_clause.title)
          end
        end
      end
    end
  end
end
