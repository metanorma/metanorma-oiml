# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Transforms inline-level Metanorma elements into NISO STS inline
        # equivalents.
        class InlineTransformer < Base
          INLINE_MAP = {
            "em"     => "italic",
            "strong" => "bold",
            "tt"     => "monospace",
            "code"   => "inline-code",
            "sub"    => "sub",
            "sup"    => "sup"
          }.freeze

          def transform_children(source_node, builder)
            source_node.children.each do |child|
              transform_node(child, builder)
            end
          end

          def transform_node(node, builder)
            case node
            when Nokogiri::XML::Text then builder.text(node.text)
            when Nokogiri::XML::Element then transform_element(node, builder)
            end
          end

          private

          def transform_element(node, builder)
            case node.name
            when "br", "tab"
              builder.text(" ")
            when "xref"
              transform_xref(node, builder)
            when "link"
              transform_link(node, builder)
            when "fn"
              transform_fn(node, builder)
            when "image"
              transform_inline_graphic(node, builder)
            when "fmt-xref", "fmt-link", "fmt-name"
              transform_children(node, builder)
            else
              tag = INLINE_MAP[node.name]
              if tag
                builder.public_send(tag) { transform_children(node, builder) }
              else
                transform_children(node, builder)
              end
            end
          end

          def transform_xref(node, builder)
            rid = node["target"] || node["refid"] || node["rid"]
            return unless rid

            ref_type = ref_type_for(node["type"])
            builder.xref("rid" => rid, "ref-type" => ref_type) do
              transform_children(node, builder)
            end
          end

          def transform_link(node, builder)
            href = node["target"] || node["href"]
            return transform_children(node, builder) unless href

            builder.ext_link("ext-link-type" => "uri",
                             "xmlns:xlink" => StsXml::XLINK_NS,
                             "xlink:href" => href) do
              transform_children(node, builder)
            end
          end

          def transform_fn(node, builder)
            source_id = node["id"] || node["reference"]
            return unless source_id

            sts_id = context.footnote_collector.register(source_id)
            builder.xref("rid" => sts_id, "ref-type" => "fn") do
              builder.text(node["reference"] || source_id)
            end
          end

          def transform_inline_graphic(node, builder)
            href = node["src"] || node["href"]
            return unless href

            builder.inline_graphic("xmlns:xlink" => StsXml::XLINK_NS,
                                   "xlink:href" => href)
          end

          def ref_type_for(mn_type)
            case mn_type
            when "clause", "section" then "sec"
            when "table" then "table"
            when "figure", "fig" then "fig"
            when "formula" then "other"
            when "fn", "footnote" then "fn"
            when "bibitem", "bibr" then "bibr"
            else "other"
            end
          end
        end
      end
    end
  end
end
