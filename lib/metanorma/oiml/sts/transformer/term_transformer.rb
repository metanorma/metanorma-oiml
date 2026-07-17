# frozen_string: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class TermTransformer < Base
          def transform(source_term)
            content = []

            add_preferred_name(content, source_term)
            add_definition(content, source_term)
            add_standalone_paragraphs(content, source_term)
            add_lists(content, source_term)
            add_term_notes(content, source_term)
            add_term_examples(content, source_term)
            add_sources(content, source_term)

            attrs = {}
            attrs[:id] = source_term.id if source_term.id
            paragraphs, lists = partition_content(content)
            attrs[:paragraph] = paragraphs if paragraphs.any?
            attrs[:list] = lists if lists.any?

            nested = Array(source_term.term).map { |sub| transform(sub) }
            attrs[:sec] = nested if nested.any?

            ::Sts::IsoSts::Sec.new(attrs)
          end

          def partition_content(content)
            paragraphs = content.grep(::Sts::IsoSts::Paragraph)
            lists = content.grep(::Sts::IsoSts::List)
            others = content.reject { |c| c.is_a?(::Sts::IsoSts::Paragraph) || c.is_a?(::Sts::IsoSts::List) }
            [paragraphs + others, lists]
          end

          private

          def add_preferred_name(content, source_term)
            text = preferred_name_text(source_term)
            return if text.nil? || text.empty?

            content << ::Sts::IsoSts::Paragraph.new(content: [text])
          end

          # Preferred names often contain math (e.g. "maximum capacity
          # (E_max)"). The typed TermNameElement drops stems, so we
          # prefer the rendered fmt_preferred tree when present and
          # fall back to the semantic expression name.
          def preferred_name_text(source_term)
            fmt = Array(source_term.fmt_preferred).first if source_term.respond_to?(:fmt_preferred)
            return RenderedTextExtractor.text_of(fmt_para(fmt)) if fmt && fmt.respond_to?(:p)

            preferred = Array(source_term.preferred).first
            return nil unless preferred

            expression = preferred.expression
            return RenderedTextExtractor.text_of(preferred) unless expression

            names = Array(expression.name)
            return RenderedTextExtractor.text_of(preferred) if names.empty?

            RenderedTextExtractor.text_of(names.first)
          end

          def fmt_para(fmt)
            Array(fmt.p).first
          end

          def add_definition(content, source_term)
            definition = Array(source_term.definition).first
            return unless definition

            vd = definition.verbal_definition
            return unless vd

            Array(vd.p).each { |p| content << paragraph_transformer.transform(p) }
          end

          def add_standalone_paragraphs(content, source_term)
            Array(source_term.p).each { |p| content << paragraph_transformer.transform(p) }
          end

          def add_lists(content, source_term)
            definition = Array(source_term.definition).first
            return unless definition

            vd = definition.verbal_definition
            return unless vd

            Array(vd.ul).each { |ul| content << build_list(ul, "bullet") }
            Array(vd.ol).each { |ol| content << build_list(ol, "order") }
          end

          def add_list_items(content, list)
            Array(list.listitem).each do |li|
              Array(li.paragraphs).each { |p| content << paragraph_transformer.transform(p) }
            end
          end

          def add_term_notes(content, source_term)
            Array(source_term.termnote).each { |tn| add_typed_note_paragraphs(content, tn, "Note", colon: true) }
          end

          def add_term_examples(content, source_term)
            Array(source_term.termexample).each { |te| add_typed_note_paragraphs(content, te, "Example", colon: true) }
          end

          def add_typed_note_paragraphs(content, note_obj, label, colon: false)
            suffix = colon ? ": " : "  "
            Array(note_obj.p).each_with_index do |p, i|
              para = paragraph_transformer.transform(p)
              if i.zero?
                existing = para.content.to_a
                para.content = ["#{label}#{suffix}#{existing.first || ''}"] + existing[1..]
              end
              content << para
            end
            Array(note_obj.ul).each { |ul| content << build_list(ul, "bullet") }
            Array(note_obj.ol).each { |ol| content << build_list(ol, "order") }
          end

          def build_list(list, list_type)
            list_transformer.transform_with_type(list, list_type)
          end

          def add_sources(content, source_term)
            Array(source_term.source).each { |s| content << build_source(s) }
          end

          def build_source(source)
            origin = source.origin
            return nil unless origin

            citeas = origin.citeas
            locality = extract_locality(origin)
            ordinal = bib_ordinal(origin)

            text = "[SOURCE: #{citeas}"
            if locality
              text << ", #{locality}"
              text << "[#{ordinal}]" if ordinal
              text << " "
            end
            text << "]"
            ::Sts::IsoSts::Paragraph.new(content: [text])
          end

          def extract_locality(origin)
            ls_arr = origin.locality_stack
            return nil unless ls_arr.is_a?(Array) && ls_arr.any?

            parts = []
            ls_arr.each do |ls|
              Array(ls.bib_locality).each do |loc|
                from = loc.reference_from
                val = case from
                      when String then from
                      when nil then ""
                      else
                        cv = from.content rescue nil
                        cv ? Array(cv).first.to_s : from.to_s
                      end
                parts << val if val && !val.empty?
              end
            end
            parts.empty? ? nil : parts.join(", ")
          end

          def bib_ordinal(origin)
            bibitemid = origin.bibitemid
            return nil unless bibitemid

            bib = context.source.typed_root.bibliography
            return nil unless bib

            items = Array(bib.references).flat_map { |rs| Array(rs.references) }
            items.each_with_index do |item, i|
              return (i + 1).to_s if item.id == bibitemid || item.anchor == bibitemid
            end
            nil
          end
        end
      end
    end
  end
end
