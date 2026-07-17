# frozen_string_literal: true

require "metanorma/document"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class SourceDocument
          attr_reader :typed_root

          def self.parse(input)
            xml_string = input.respond_to?(:read) ? input.read : input.to_s
            typed = Metanorma::OimlDocument::Root.from_xml(xml_string)
            new(typed)
          end

          def initialize(typed_root)
            @typed_root = typed_root
          end

          def bibdata
            typed_root.bibdata
          end

          def language
            return "en" unless bibdata

            langs = bibdata.language rescue nil
            return "en" unless langs

            lang = langs.first if langs.is_a?(Array)
            val = lang.respond_to?(:value) ? lang.value : lang.to_s
            val.to_s.strip.match?(/\A[a-z]{2}(-[A-Z]{2})?\z/) ? val.to_s.strip : "en"
          end

          def docidentifier
            return nil unless bibdata

            ids = bibdata.doc_identifier rescue nil
            return nil unless ids

            Array(ids).each do |id_obj|
              next if id_obj.type
              return text_of(id_obj)
            end
            text_of(Array(ids).first)
          end

          def text_of(obj)
            return obj if obj.is_a?(String)
            return "" unless obj

            val = (obj.value rescue nil) || (obj.content rescue nil) || (obj.text rescue nil)
            return "" unless val

            Array(val).map { |v| v.is_a?(String) ? v : text_of(v) }.join.strip
          end

          def title(type: nil)
            return nil unless bibdata

            titles = bibdata.titles rescue bibdata.title rescue nil
            return nil unless titles

            titles = Array(titles)
            t = titles.find { |x| type.nil? || (x.type == type rescue false) } || titles.first
            text_of(t)
          end

          # Assemble the rendered document title using title_main +
          # title_part_prefix + title_part, matching how Metanorma
          # HTML renders the coverpage title.
          def formatted_title
            return title unless bibdata

            iso_title = bibdata.title
            return title unless iso_title

            main = abstract_title_value(iso_title.title_main)
            part_prefix = abstract_title_value(iso_title.title_part_prefix)
            part = abstract_title_value(iso_title.title_part)

            segments = [main]
            if part_prefix && !part_prefix.empty?
              # Metanorma HTML renders "Part 1:Subtitle" without space after
              # colon when concatenating prefix + part. Match that here.
              segments << (part && !part.empty? ? "#{part_prefix}:#{part}" : part_prefix)
            elsif part && !part.empty?
              segments << part
            end
            segments.compact!(&:empty?)
            return title if segments.empty?

            segments.join(" — ")
          end

          def abstract_title_value(abstract)
            return nil if abstract.nil?
            val = abstract.value rescue nil
            val.nil? ? nil : val.to_s.strip
          end

          def copyright_year
            return nil unless bibdata

            cps = bibdata.copyright rescue nil
            return nil unless cps

            cp = Array(cps).first
            return nil unless cp

            from = cp.from rescue nil
            return text_of(from) unless from.nil?

            nil
          end

          def copyright_holder
            return nil unless bibdata

            cps = bibdata.copyright rescue nil
            return nil unless cps

            cp = Array(cps).first
            return nil unless cp

            owner = cp.owner rescue nil
            return nil unless owner

            org = Array(owner.organization).first rescue nil
            return nil unless org

            name = org.name rescue nil
            return text_of(name) if name

            nil
          end

          def publisher
            ch = copyright_holder
            return ch if ch

            return nil unless bibdata

            Array(bibdata.contributor).each do |c|
              role = Array(c.role).first rescue nil
              next unless role && (role.type == "publisher" rescue false)

              org = Array(c.organization).first rescue nil
              return text_of(org)
            end
            nil
          end

          def pub_date
            return nil unless bibdata

            dates = bibdata.date rescue nil
            return copyright_year unless dates

            pub = Array(dates).find { |d| (d.type rescue nil) == "published" } || Array(dates).first
            return copyright_year unless pub

            val = text_of(pub)
            val.empty? ? copyright_year : val
          end

          def stage_code
            return nil unless bibdata&.status

            bibdata.status.respond_to?(:stage) ? bibdata.status.stage.to_s.strip : nil
          end

          def foreword
            typed_root.preface&.foreword
          end

          def introduction
            typed_root.preface&.introduction
          end

          def sections
            secs = typed_root.sections
            return [] unless secs

            Array(secs.clause)
          end

          def sections_block_other_children
            []
          end

          def annexes
            Array(typed_root.annex)
          end

          def bibliography
            bib = typed_root.bibliography
            return [] unless bib&.respond_to?(:references)

            Array(bib.references)
          end

          def front?
            !foreword.nil? || !introduction.nil?
          end

          def has_metadata?
            !docidentifier.nil?
          end

          def has_back?
            annexes.any? || bibliography.any?
          end

          # Look up the autonum (e.g. "3.1.3.1") for a term by id.
          # Returns nil if not found.
          def term_autonum_for(term_id)
            @term_autonum_cache ||= build_term_autonum_cache
            @term_autonum_cache[term_id]
          end

          private

          def build_term_autonum_cache
            cache = {}
            walk_for_terms(typed_root) do |term|
              next unless term.respond_to?(:id)
              autonum = extract_term_autonum(term)
              cache[term.id] = autonum if autonum && !autonum.empty?
            end
            cache
          end

          def walk_for_terms(node, &blk)
            yield(node) if node.class.name&.end_with?("::IsoTerm") ||
                           node.class.name&.end_with?("::Term") &&
                           node.respond_to?(:id)

            if node.respond_to?(:clause)
              Array(node.clause).each { |c| walk_for_terms(c, &blk) }
            end
            if node.respond_to?(:sections) && node.sections.respond_to?(:clause)
              Array(node.sections.clause).each { |c| walk_for_terms(c, &blk) }
            end
            if node.respond_to?(:terms) && node.terms.is_a?(Array)
              node.terms.each { |t| walk_for_terms(t, &blk) }
            end
            if node.respond_to?(:term)
              Array(node.term).each { |t| walk_for_terms(t, &blk) }
            end
          end

          def extract_term_autonum(term)
            label_arr = Array(term.fmt_xref_label)
            label = label_arr.first
            return nil unless label

            # FmtXrefLabelElement children alternate: SemxElement (autonum),
            # SpanElement (delimiter "."). Walk via each_mixed_content to
            # reconstruct e.g. "3.1.3.1".
            return nil unless label.respond_to?(:each_mixed_content)

            parts = []
            label.each_mixed_content do |n|
              if n.is_a?(String) && !n.strip.empty?
                parts << n.strip
              else
                cn = n.class.name.split("::").last
                case cn
                when "SemxElement"
                  txt = semx_text(n)
                  parts << txt if txt && !txt.empty?
                when "SpanElement"
                  txt = span_text(n)
                  parts << txt if txt && !txt.empty?
                end
              end
            end
            joined = parts.join.strip
            joined.empty? ? nil : joined
          end

          def semx_text(semx)
            return semx.to_s unless semx.respond_to?(:each_mixed_content)

            parts = []
            semx.each_mixed_content do |n|
              if n.is_a?(String)
                parts << n
              else
                # nested autonum element
                txt = autonum_text(n)
                parts << txt if txt && !txt.empty?
              end
            end
            parts.join
          end

          def span_text(span)
            return "" unless span.respond_to?(:each_mixed_content)

            parts = []
            span.each_mixed_content { |n| parts << n if n.is_a?(String) }
            parts.join
          end

          def autonum_text(node)
            return "" unless node.respond_to?(:each_mixed_content)

            parts = []
            node.each_mixed_content { |n| parts << n if n.is_a?(String) }
            parts.join
          end
        end
      end
    end
  end
end
