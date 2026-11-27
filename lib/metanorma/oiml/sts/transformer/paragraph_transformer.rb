# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ParagraphTransformer < Metanorma::Document::Sts::Transformer::ParagraphTransformer
          private

          # Serializable#to_s is #inspect: degrading a model child (e.g. a
          # nested Xref inside a <sup>) through to_s leaked object addresses
          # into the output, so degrade to the visible text instead.
          def attach_inline_child(container, child)
            case container
            when ::Sts::NisoSts::Paragraph
              attach_to_paragraph(container, child)
            when ::Sts::TbxIsoTml::Bold, ::Sts::TbxIsoTml::Italic
              attach_to_rich_inline(container, child)
            else
              container.content RenderedTextExtractor.text_of(child).to_s
            end
          end

          # The OIML stem models expose their MathML through a method, not a
          # declared attribute; the OIML MathmlBuilder reads either form.
          def build_inline_formula(stem_node)
            mirror = lookup_stem_mirror(stem_node)
            ::Metanorma::Oiml::Sts::MathmlBuilder.inline_formula_from_stem(mirror || stem_node)
          end

          # An xref to an unclassified anchor is "other" for OIML (the
          # engine defaults it to "table", the ISO requirement-table case).
          def requirement_anchor_ref_type(node, _rid)
            style =
              if node.is_a?(Metanorma::Document::Components::Inline::FmtXrefElement)
                ""
              else
                node.style.to_s
              end
            style = @mirror_style.to_s if style.empty? && @mirror_style
            case style
            when "clause", "section" then "sec"
            when "table" then "table"
            when "figure", "fig" then "fig"
            when "fn", "footnote" then "fn"
            else "other"
            end
          end
        end
      end
    end
  end
end
