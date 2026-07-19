# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class TableTransformer < Base
          def transform(source_table)
            attrs = {}
            attrs[:id] = source_table.id if source_table.class.method_defined?(:id) && source_table.id
            label = table_label(source_table)
            attrs[:label] = label if label
            caption = table_caption(source_table)
            attrs[:caption] = caption if caption
            table = build_table(source_table)
            attrs[:table] = [table] if table
            ::Sts::TbxIsoTml::TableWrap.new(attrs)
          end

          private

          # "Table 2" from the presentation XML autonum attribute.
          def table_label(source_table)
            return nil unless source_table.class.method_defined?(:autonum) && source_table.autonum

            "Table #{source_table.autonum}"
          end

          def table_caption(source_table)
            return nil unless source_table.class.method_defined?(:name) && source_table.name

            text = RenderedTextExtractor.text_of(source_table.name).strip
            return nil if text.empty?

            ::Sts::NisoSts::Caption.new(
              title: ::Sts::NisoSts::Title.new(content: [text])
            )
          end

          def build_table(source_table)
            attrs = {}
            if source_table.class.method_defined?(:thead) && source_table.thead
              attrs[:thead] = build_section(source_table.thead, ::Sts::TbxIsoTml::Thead)
            end
            if source_table.class.method_defined?(:tbody) && source_table.tbody
              attrs[:tbody] = build_section(source_table.tbody, ::Sts::TbxIsoTml::Tbody)
            end
            ::Sts::TbxIsoTml::Table.new(attrs)
          end

          def build_section(source_section, klass)
            trs = Array(source_section.tr).map { |tr| build_tr(tr) }
            klass.new(tr: trs)
          end

          def build_tr(tr)
            th_cells = Array(tr.th).map { |c| build_cell(c, ::Sts::TbxIsoTml::Th) }
            td_cells = Array(tr.td).map { |c| build_cell(c, ::Sts::TbxIsoTml::Td) }
            attrs = {}
            attrs[:th] = th_cells if th_cells.any?
            attrs[:td] = td_cells if td_cells.any?
            ::Sts::TbxIsoTml::Tr.new(attrs)
          end

          def build_cell(cell, klass)
            entries = cell_entries(cell)
            klass.new do |c|
              entries.each do |kind, value|
                case kind
                when :text then c.content value
                when :inline_formula then c.inline_formula value
                when :monospace then c.monospace value
                when :bold then c.bold value
                when :italic then c.italic value
                end
              end
            end
          end

          # Walks the cell's mixed content in document order and produces
          # an array of [:text, String] | [:inline_formula, InlineFormula] |
          # [:monospace|:bold|:italic, model] tuples. The builder in
          # build_cell routes them to the correct typed collection on the
          # Td/Th model, preserving cross-type ordering via lutaml-model's
          # mixed_content element_order.
          def cell_entries(cell)
            entries = []
            current_text = nil
            flush = lambda do
              return if current_text.nil?
              entries << [:text, current_text]
              current_text = nil
            end

            walk_cell(cell) do |kind, node, text|
              case kind
              when :text
                current_text = (current_text || "") + text
              when :stem
                formula = build_inline_formula(node)
                next unless formula

                flush.call
                entries << [:inline_formula, formula]
              when :monospace
                flush.call
                entries << [:monospace, ::Sts::NisoSts::Monospace.new(content: [text])]
              when :bold
                flush.call
                entries << [:bold, ::Sts::TbxIsoTml::Bold.new(content: [text])]
              when :italic
                flush.call
                entries << [:italic, ::Sts::TbxIsoTml::Italic.new(content: [text])]
              end
            end
            flush.call
            entries
          end

          def walk_cell(cell)
            return unless cell.class.method_defined?(:each_mixed_content)

            cell.each_mixed_content do |node|
              if node.is_a?(String)
                yield(:text, node, node)
                next
              end

              case node.class.name&.split("::")&.last
              when "StemInlineElement", "StemBlockElement", "FmtStemElement"
                yield(:stem, node, nil)
              when "AsciimathElement"
                next
              when "TtElement", "MonospaceElement"
                yield(:monospace, node, RenderedTextExtractor.text_of(node))
              when "StrongRawElement", "StrongElement"
                yield(:bold, node, RenderedTextExtractor.text_of(node))
              when "EmRawElement", "EmElement"
                yield(:italic, node, RenderedTextExtractor.text_of(node))
              else
                text = RenderedTextExtractor.text_of(node)
                yield(:text, node, text) if text && !text.empty?
              end
            end
          end

          def build_inline_formula(stem_node)
            ::Metanorma::Oiml::Sts::MathmlBuilder.inline_formula_from_stem(
              stem_node,
              klass: ::Sts::NisoSts::InlineFormula
            )
          end
        end
      end
    end
  end
end
