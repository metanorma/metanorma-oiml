# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ReferenceTransformer < Base
          def transform_section(ref_section)
            bibitems = extract_bibitems(ref_section)
            refs = bibitems.map.with_index { |b, i| transform_bibitem(b, i + 1) }.compact
            content_type = (ref_section.respond_to?(:normative) && ref_section.normative) ? "normative-refs" : "bibliography"
            title_text = extract_section_title(ref_section) || (content_type == "normative-refs" ? "Normative References" : "Bibliography")
            title = ::Sts::IsoSts::Title.new(content: [title_text])
            ModelBuilder.ref_list(content_type: content_type, refs: refs, title: title)
          end

          def extract_section_title(ref_section)
            return nil unless ref_section.respond_to?(:title)

            title = ref_section.title
            return nil unless title

            val = (title.text rescue nil) || (title.content rescue nil)
            val = Array(val).first if val.is_a?(Array)
            val.to_s.strip
          end

          def transform_bibitem(bibitem, ordinal = nil)
            identifier = extract_docidentifier(bibitem)
            formattedref = extract_formattedref(bibitem)
            year = extract_year(bibitem)
            org = publisher_org(identifier)

            # Build label like "[1]"
            label_text = ordinal ? "[#{ordinal}]" : nil

            # Build content text: "OIML V 1:2013, International Vocabulary..."
            content_parts = []
            content_parts << identifier if identifier
            content_parts << formattedref if formattedref
            content_text = content_parts.join(", ")

            ModelBuilder.ref_with_label_and_std(
              label: label_text,
              org: org,
              identifier: identifier,
              title: formattedref,
              year: year,
              content_text: content_text
            )
          end

          private

          def extract_bibitems(ref_section)
            return Array(ref_section.references) if ref_section.respond_to?(:references)

            []
          end

          def extract_docidentifier(bibitem)
            return nil unless bibitem.respond_to?(:docidentifier)

            ids = Array(bibitem.docidentifier)
            return nil if ids.empty?

            primary = ids.find { |i| !(i.respond_to?(:type) && i.type) } || ids.first
            value_of(primary)
          end

          def extract_formattedref(bibitem)
            fr = if bibitem.respond_to?(:formatted_ref)
                   bibitem.formatted_ref
                 elsif bibitem.respond_to?(:formattedref)
                   bibitem.formattedref
                 end
            return nil unless fr

            # Walk via each_mixed_content to get all inline text
            if fr.respond_to?(:each_mixed_content)
              text_parts = []
              fr.each_mixed_content do |n|
                if n.is_a?(String)
                  text_parts << n
                else
                  text_parts << extract_text_recursive(n).to_s
                end
              end
              text = text_parts.join.strip
              return text unless text.empty?
            end

            nil
          end

          def extract_text_recursive(obj)
            return obj.to_s.strip if obj.is_a?(String)
            return nil unless obj

            if obj.respond_to?(:each_mixed_content)
              parts = []
              obj.each_mixed_content do |n|
                if n.is_a?(String)
                  parts << n
                else
                  sub = extract_text_recursive(n)
                  parts << sub.to_s if sub && !sub.empty?
                end
              end
              joined = parts.join.strip
              return joined unless joined.empty?
            end

            %i[text content value].each do |m|
              if obj.respond_to?(m)
                begin
                  v = obj.public_send(m)
                  result = extract_text_recursive(v)
                  return result if result && !result.empty?
                rescue StandardError
                  next
                end
              end
            end
            nil
          end

          def extract_title(bibitem)
            return nil unless bibitem.respond_to?(:title)

            titles = Array(bibitem.title)
            return nil if titles.empty?

            value_of(titles.first)
          end

          def extract_year(bibitem)
            return nil unless bibitem.respond_to?(:date)

            dates = Array(bibitem.date)
            return nil if dates.empty?

            pub = dates.find { |d| d.respond_to?(:type) && d.type == "published" } || dates.first
            return nil unless pub

            on = pub.respond_to?(:on) ? pub.on : nil
            return nil unless on

            val = (on.content rescue nil) || (on.id rescue nil) || (on.value rescue nil) || on.to_s
            val.to_s[/\d{4}/]
          end

          def value_of(obj)
            return obj.to_s.strip if obj.is_a?(String)
            return "" unless obj

            val = (obj.id rescue nil) || (obj.value rescue nil) || (obj.content rescue nil) || (obj.text rescue nil)
            val.to_s.strip
          end

          def publisher_org(identifier)
            case identifier.to_s
            when /\AOIML\b/, /\AR[A-Z]\d/ then "OIML"
            when /\AISO\b/  then "ISO"
            when /\AIEC\b/  then "IEC"
            when /\AANSI\/NISO\b/ then "NISO"
            else "OIML"
            end
          end
        end
      end
    end
  end
end
