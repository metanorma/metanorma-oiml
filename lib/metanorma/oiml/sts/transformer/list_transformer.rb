# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ListTransformer < Base
          def transform(source_list)
            list_type = source_list.is_a?(Metanorma::Document::Components::Lists::OrderedList) ? "order" : "bullet"
            items = Array(source_list.listitem).map { |li| build_list_item(li) }

            ::Sts::IsoSts::List.new(list_type: list_type, list_item: items)
          end

          # Like #transform but lets the caller specify the list type
          # explicitly. Useful when the typed Ruby class of the source
          # list is ambiguous (e.g. note's ul/ol accessors).
          def transform_with_type(source_list, list_type)
            items = Array(source_list.listitem).map { |li| build_list_item(li) }
            ::Sts::IsoSts::List.new(list_type: list_type, list_item: items)
          end

          def transform_def_list(source_dl)
            items = Array(source_dl.dt).zip(Array(source_dl.dd)).map do |dt, dd|
              build_def_item(dt, dd)
            end.compact

            ::Sts::IsoSts::DefList.new(def_item: items)
          end

          private

          def build_def_item(dt, dd)
            term = text_of(dt)
            desc = extract_dd_text(dd)
            return nil unless term || desc

            attrs = {}
            attrs[:term] = ::Sts::IsoSts::Term.new(content: [term]) if term && !term.empty?
            if desc && !desc.empty?
              attrs[:def] = ::Sts::IsoSts::Def.new(
                paragraph: [::Sts::IsoSts::Paragraph.new(content: [desc])]
              )
            end
            ::Sts::IsoSts::DefItem.new(attrs)
          end

          def extract_dd_text(dd)
            return nil unless dd
            return dd.to_s if dd.is_a?(String)

            # DdElement stores content in .p (ParagraphBlock collection)
            ps = Array(dd.p)
            return text_of(dd) if ps.empty?

            texts = ps.map { |p| text_of(p) }.reject(&:empty?)
            texts.empty? ? nil : texts.join(" ")
          end

          def text_of(obj)
            return obj.to_s if obj.is_a?(String)
            return nil unless obj

            val = (obj.text rescue nil) || (obj.content rescue nil)
            val = Array(val).first if val.is_a?(Array)
            val.to_s.strip
          end

          def build_list_item(li)
            paragraphs = []
            nested_lists = []

            if li.respond_to?(:text)
              text_strings = Array(li.text).map(&:to_s).reject(&:empty?)
              if text_strings.any?
                paragraphs << ::Sts::IsoSts::Paragraph.new(content: text_strings)
              end
            end
            if li.respond_to?(:paragraphs)
              Array(li.paragraphs).each { |p| paragraphs << paragraph_transformer.transform(p) }
            end
            if li.respond_to?(:unordered_lists)
              Array(li.unordered_lists).each { |ul| nested_lists << transform(ul) }
            end
            if li.respond_to?(:ordered_lists)
              Array(li.ordered_lists).each { |ol| nested_lists << transform(ol) }
            end

            attrs = {}
            attrs[:paragraph] = paragraphs if paragraphs.any?
            attrs[:list] = nested_lists if nested_lists.any?
            ::Sts::IsoSts::ListItem.new(attrs)
          end
        end
      end
    end
  end
end
