# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class TableTransformer < Base
          def transform(source_table)
            attrs = {}
            attrs[:id] = source_table.id if source_table.respond_to?(:id) && source_table.id
            table = build_table(source_table)
            attrs[:table] = [table] if table
            ::Sts::TbxIsoTml::TableWrap.new(attrs)
          end

          private

          def build_table(source_table)
            return nil unless source_table.respond_to?(:thead) || source_table.respond_to?(:tbody)

            attrs = {}
            if source_table.respond_to?(:thead) && source_table.thead
              attrs[:thead] = build_section(source_table.thead, ::Sts::TbxIsoTml::Thead)
            end
            if source_table.respond_to?(:tbody) && source_table.tbody
              attrs[:tbody] = build_section(source_table.tbody, ::Sts::TbxIsoTml::Tbody)
            end
            ::Sts::TbxIsoTml::Table.new(attrs)
          end

          def build_section(source_section, klass)
            trs = Array(source_section.respond_to?(:tr) ? source_section.tr : []).map do |tr|
              build_tr(tr)
            end
            klass.new(tr: trs)
          end

          def build_tr(tr)
            th_cells = Array(tr.respond_to?(:th) ? tr.th : []).map { |c| build_cell(c, ::Sts::TbxIsoTml::Th) }
            td_cells = Array(tr.respond_to?(:td) ? tr.td : []).map { |c| build_cell(c, ::Sts::TbxIsoTml::Td) }
            attrs = {}
            attrs[:th] = th_cells if th_cells.any?
            attrs[:td] = td_cells if td_cells.any?
            ::Sts::TbxIsoTml::Tr.new(attrs)
          end

          def build_cell(cell, klass)
            attrs = {}
            attrs[:align] = cell.align if cell.respond_to?(:align) && cell.align
            attrs[:valign] = cell.valign if cell.respond_to?(:valign) && cell.valign

            # Use RenderedTextExtractor so math content and thousands
            # separators from fmt-stem are preserved (matching MN HTML).
            text = ::Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor.text_of(cell)
            attrs[:content] = [text] unless text.nil? || text.empty?

            klass.new(attrs)
          end

          PRESENTATION_CLASS_NAMES = %w[
            FmtTitleElement FmtXrefLabelElement FmtNameElement FmtStemElement
            FmtFnLabelElement FmtAnnotationStartElement FmtAnnotationEndElement
            FmtConceptElement SemxElement LocalizedString LocalizedStrings
            FmtVal AsciiMath BrElement TabElement Bookmark SpanElement
          ].freeze

          def walk_cell_inline(cell)
            return unless cell.respond_to?(:each_mixed_content)

            cell.each_mixed_content do |node|
              if node.is_a?(String)
                yield(:text, node, node)
                next
              end

              cn = node.class.name&.split("::")&.last
              next if PRESENTATION_CLASS_NAMES.include?(cn)

              case cn
              when "EmRawElement", "EmElement"
                yield(:italic, node, text_of(node))
              when "StrongRawElement", "StrongElement"
                yield(:bold, node, text_of(node))
              when "SubElement"
                yield(:sub, node, text_of(node))
              when "SupElement"
                yield(:sup, node, text_of(node))
              when "TtElement"
                yield(:monospace, node, text_of(node))
              when "UnderlineElement"
                yield(:underline, node, text_of(node))
              when "StrikeElement"
                yield(:strike, node, text_of(node))
              when "StemInlineElement", "StemBlockElement"
                yield(:stem, node, stem_text(node))
              when "LinkElement"
                yield(:link, node, text_of(node))
              when "XrefElement", "ErefElement"
                yield(:xref, node, text_of(node))
              end
            end
          end

          def text_of(obj)
            return obj.to_s if obj.is_a?(String)
            return "" unless obj

            val = begin
              obj.text
            rescue StandardError
              nil
            end
            return "" if val.nil?

            if val.is_a?(Array)
              val.map(&:to_s).join.strip
            else
              val.to_s.strip
            end
          end

          def stem_text(node)
            ascii = begin
              node.asciimath
            rescue StandardError
              nil
            end
            return "" if ascii.nil?

            text = extract_stem_value(ascii)
            return asciimath_to_text(text) if text && !text.empty?
            ""
          end

          def asciimath_to_text(ascii)
            text = ascii.to_s
            text = text.gsub(/(\w)_\{"([^"]+)"\}/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_\{([^}]+)\}/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_\(([^)]+)\)/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_(\w)/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)\^\{"([^"]+)"\}/) { "#{$1}#{$2}" }
            text = text.gsub(/(\w)\^\{([^}]+)\}/) { "#{$1}#{$2}" }
            text = text.gsub(/(\w)\^\(([^)]+)\)/) { "#{$1}#{$2}" }
            text = text.gsub(/(\w)\^(\w)/) { "#{$1}#{$2}" }
            text = text.gsub(/"/, "")
            text = text.gsub(/\bcdot\b/, "·")
            text = text.gsub(/\btimes\b/, "×")
            text = text.gsub(/\ble\b/, "≤")
            text = text.gsub(/\bge\b/, "≥")
            text = text.gsub(/\bne\b/, "≠")
            text = text.gsub(/\bapprox\b/, "≈")
            text = text.gsub(/->/, "→")
            text = text.gsub(/\s+/, " ")
            text.strip
          end

          def extract_stem_value(val)
            return nil if val.nil?
            return val.to_s.strip if val.is_a?(String)

            if val.is_a?(Array)
              strs = val.map { |v| extract_stem_value(v).to_s }
              return strs.join.strip
            end

            class_name = val.class.name&.split("::")&.last
            if class_name == "AsciimathElement"
              txt = val.text
              return extract_stem_value(txt) if txt
            end

            %i[text content value].each do |attr|
              if val.respond_to?(attr)
                begin
                  v = val.public_send(attr)
                  result = extract_stem_value(v)
                  return result if result && !result.empty?
                rescue StandardError
                  next
                end
              end
            end

            nil
          end

          def build_stem(node)
            text = stem_text(node)
            return nil if text.nil? || text.empty?
            ::Sts::NisoSts::InlineFormula.new(content: [text])
          end

          def build_link(node)
            href = begin
              node.target
            rescue StandardError
              nil
            end || begin
              node.href
            rescue StandardError
              nil
            end
            ::Sts::IsoSts::ExtLink.new(
              ext_link_type: "uri",
              xlink_href: href,
              content: [text_of(node)]
            )
          end

          def build_xref(node)
            rid = begin
              node.target
            rescue StandardError
              nil
            end || begin
              node.refid
            rescue StandardError
              nil
            end || begin
              node.to
            rescue StandardError
              nil
            end
            return nil unless rid

            visible_text = xref_visible_text(node, rid)
            ::Sts::TbxIsoTml::Xref.new(
              rid: rid,
              ref_type: "other",
              value: visible_text
            )
          end

          def xref_visible_text(node, rid)
            explicit = text_of(node)
            return explicit unless explicit.empty?

            case rid
            when /\Asec-(.+)\z/   then Regexp.last_match(1)
            when /\Afig-(.+)\z/   then Regexp.last_match(1)
            when /\Atable-(.+)\z/ then Regexp.last_match(1)
            when /\Afn-(.+)\z/    then Regexp.last_match(1)
            else rid
            end
          end
        end
      end
    end
  end
end
