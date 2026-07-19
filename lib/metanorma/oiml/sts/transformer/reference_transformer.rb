# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ReferenceTransformer < Base
          def transform_section(ref_section)
            bibitems = extract_bibitems(ref_section)
            refs = bibitems.map.with_index { |b, i| transform_bibitem(b, i + 1) }.compact
            title_text = extract_title(ref_section)

            paragraphs = intro_paragraphs(ref_section)
            label = section_transformer.extract_autonum(ref_section)
            if paragraphs.empty? && label.nil?
              # Back-matter bibliography: a bare ref-list.
              return ModelBuilder.ref_list(content_type: "bibliography", title: title_text, ref: refs)
            end

            # In-body normative references: a numbered <sec> whose intro
            # paragraphs precede the (untitled) ref-list.
            ref_list = ModelBuilder.ref_list(content_type: "normative-refs", title: nil, ref: refs)
            attrs = {}
            attrs[:id] = ref_section.id if ref_section.class.method_defined?(:id) && ref_section.id
            attrs[:label] = ::Sts::IsoSts::Label.new(content: [label]) if label
            attrs[:title] = ::Sts::IsoSts::Title.new(content: [title_text]) if title_text && !title_text.empty?
            attrs[:paragraph] = paragraphs if paragraphs.any?
            attrs[:ref_list] = [ref_list] if ref_list
            ::Sts::IsoSts::Sec.new(attrs)
          end

          def transform_bibitem(bibitem, ordinal = nil)
            identifier = extract_docidentifier(bibitem)
            formattedref = extract_formattedref(bibitem)
            label_text = ordinal ? "[#{ordinal}]" : nil

            content_parts = []
            content_parts << identifier if identifier
            content_parts << formattedref if formattedref

            ModelBuilder.ref(
              label: label_text,
              mixed_citation: content_parts.join(", "),
              std: build_std(identifier, formattedref)
            )
          end

          private

          # Every bibliographic <std> carries a <title> (and a pub-date
          # when the bibitem is dated) per OIML X 999 Clause 6.3. Undated
          # bibitems (e.g. nofetch entries) emit type="undated".
          def build_std(identifier, formattedref)
            return nil unless identifier || formattedref

            attrs = { type: "undated" }
            if identifier
              std_ref_attrs = { type: "undated", content: [identifier] }
              originator = extract_originator(identifier)
              if originator
                std_ref_attrs[:originator] = ::Sts::NisoSts::Originator.new(
                  content: [originator]
                )
              end
              attrs[:std_ref] = [::Sts::IsoSts::StdRef.new(std_ref_attrs)]
            end
            if formattedref
              attrs[:title] = ::Sts::IsoSts::Title.new(content: [formattedref])
            end
            ::Sts::IsoSts::Std.new(attrs)
          end

          # Leading organization token of an identifier like
          # "IEC/ISO Guidelines..." → "IEC"; nil otherwise.
          def extract_originator(identifier)
            token = identifier.to_s.split("/").first
            token if token&.match?(/\A[A-Z]{2,}\z/)
          end

          def extract_bibitems(ref_section)
            refs = ref_section.class.method_defined?(:references) ? ref_section.references : nil
            return Array(refs) if refs
            []
          end

          # Boilerplate paragraphs of an in-body references section
          # ("The following documents are referred to ...").
          def intro_paragraphs(ref_section)
            return [] unless ref_section.class.method_defined?(:p)

            Array(ref_section.p).map { |p| paragraph_transformer.transform(p) }
          end

          def extract_title(ref_section)
            return nil unless ref_section.class.method_defined?(:title) && ref_section.title
            RenderedTextExtractor.text_of(ref_section.title)
          end

          def extract_docidentifier(bibitem)
            return nil unless bibitem.class.method_defined?(:docidentifier)
            ids = Array(bibitem.docidentifier)
            primary = ids.find { |i| !(i.class.method_defined?(:type) && i.type) } || ids.first
            return nil unless primary
            val = primary.class.method_defined?(:id) ? primary.id : primary.to_s
            val.to_s.strip
          end

          def extract_formattedref(bibitem)
            fr = bibitem.class.method_defined?(:formatted_ref) ? bibitem.formatted_ref : nil
            return nil unless fr
            text = RenderedTextExtractor.text_of(fr)
            text.empty? ? nil : text
          end
        end
      end
    end
  end
end
