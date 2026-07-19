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

            # Dispatch terms sections (a top-level <terms> carries its
            # entries directly in .term; a clause's nested terms section
            # appears in .terms).
            terms_sections = []
            terms_sections << source_clause if source_clause.class.method_defined?(:term)
            terms_sections.concat(Array(source_clause.terms)) if source_clause.class.method_defined?(:terms)
            terms_sections.each do |terms_section|
              Array(terms_section.term).each do |term|
                term_sec = term_transformer.transform(term)
                nested_clauses << term_sec if term_sec
              end
            end

            attrs = {}
            attrs[:id] = id_val if id_val
            attrs[:title] = ::Sts::IsoSts::Title.new(content: [title_text]) if title_text && !title_text.empty?
            autonum = extract_autonum(source_clause)
            attrs[:label] = ::Sts::IsoSts::Label.new(content: [autonum]) if autonum

            paragraphs, lists, figs, tables, notes, examples, formulas, def_lists, preformats, sub_secs = [], [], [], [], [], [], [], [], [], []
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
              when ::Sts::IsoSts::Preformat then preformats << item
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
            attrs[:preformat] = preformats if preformats.any?
            attrs[:sec] = nested_clauses if nested_clauses.any?

            ::Sts::IsoSts::Sec.new(attrs)
          end

          # Section number from the presentation XML: the autonum
          # attribute (annexes, term notes) or the fmt-title/fmt-name
          # caption-label's autonum semx ("1", "8.1", "3.1"). The delim
          # between number and title is a <tab/>, which text extraction
          # drops, so the caption-label span must be isolated —
          # splitting the whole fmt-title text would glue number and
          # title together ("1Scope").
          def extract_autonum(source_clause)
            if source_clause.class.method_defined?(:autonum) && source_clause.autonum
              return source_clause.autonum.to_s
            end

            title_wrapper = %i[fmt_title fmt_name].filter_map do |method|
              source_clause.public_send(method) if source_clause.class.method_defined?(method)
            end.first
            title_wrapper = Array(title_wrapper).first
            return nil unless title_wrapper

            caption_label_text(title_wrapper)
          end

          private

          def extract_title(source_clause)
            return nil unless source_clause.class.method_defined?(:title) && source_clause.title
            RenderedTextExtractor.text_of(source_clause.title)
          end

          # Text of the <span class="fmt-caption-label"> inside a
          # fmt-title — the bare section number.
          def caption_label_text(fmt_title)
            return nil unless fmt_title.class.method_defined?(:each_mixed_content)

            label_span = nil
            fmt_title.each_mixed_content do |child|
              if child.is_a?(Metanorma::Document::Components::Inline::SpanElement) &&
                  child.class_attr == "fmt-caption-label"
                label_span = child
                break
              end
            end
            return nil unless label_span

            text = RenderedTextExtractor.text_of(label_span).strip
            text.empty? ? nil : text
          end
        end
      end
    end
  end
end
