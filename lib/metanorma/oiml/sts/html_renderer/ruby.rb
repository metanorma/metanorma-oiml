# frozen_string_literal: true

require "cgi"
require "liquid"
require "sts"

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        # Ruby fallback renderer: walks the sts-ruby typed model and emits
        # HTML through Liquid templates. No Nokogiri, no XSLT engine —
        # STS XML is parsed once into the typed model (sts-ruby) and the
        # output markup lives entirely in the Liquid templates under
        # +templates/+, which an organization can override by passing a
        # custom +templates_dir+.
        class Ruby
          TEMPLATES_DIR = File.expand_path("templates", __dir__)

          ISO = ::Sts::IsoSts
          NISO = ::Sts::NisoSts
          TBX = ::Sts::TbxIsoTml

          # Containers that render their children with no wrapper element.
          TRANSPARENT = [ISO::Standard, ISO::Front, ISO::Back, ISO::AppGroup,
                         ISO::Permissions, ISO::TitleWrap, ISO::DefItem,
                         ISO::FnGroup, ISO::StyledContent, ISO::Preformat,
                         NISO::BoxedText, NISO::EditingInstruction].freeze

          META = [ISO::IsoMeta, ISO::RegMeta, ISO::NatMeta].freeze

          SECTION = [ISO::Sec, ISO::App, ISO::TermSec].freeze

          # Inline phrase-level elements → HTML tag.
          INLINE_TAGS = {
            ISO::Bold => "strong",
            ISO::Italic => "em",
            ISO::Monospace => "code",
            ISO::Sub => "sub",
            ISO::Sup => "sup",
            ISO::Sc => "span",
            ISO::Strike => "s",
            ISO::Underline => "u",
          }.freeze

          def initialize(templates_dir: nil)
            @templates_dir = templates_dir || TEMPLATES_DIR
            @liquid_env = Liquid::Environment.new
            @liquid_env.file_system = Liquid::LocalFileSystem.new(@templates_dir)
            @template_cache = {}
          end

          def render(model_or_xml)
            render_node(coerce_model(model_or_xml))
          end

          private

          def coerce_model(input)
            return input if input.is_a?(Lutaml::Model::Serializable)

            ::Sts::IsoSts::Standard.from_xml(input.to_s)
          end

          # ----------------------------------------------------------------
          # Dispatch
          # ----------------------------------------------------------------

          def render_node(node)
            case node
            when String then escape(node)
            when *TRANSPARENT then render_children(node)
            when *META then render_meta(node)
            when ISO::Body then render_element("main", render_children(node))
            when *SECTION then render_element("section", render_children(node), id: node.id)
            when ISO::Label then render_element("span", render_inline(node), css: "label")
            when ISO::Title then render_element("h2", render_inline(node))
            when ISO::Paragraph then render_element("p", render_inline(node), id: node.id)
            when ISO::List then render_list(node)
            when ISO::ListItem then render_element("li", render_children(node))
            when ISO::DefList then render_element("dl", render_children(node))
            when ISO::Fig then render_element("figure", render_children(node))
            when ISO::Caption then render_element("figcaption", render_inline(node))
            when ISO::Graphic then render_graphic(node)
            when ISO::DispFormula then render_element("div", render_inline(node), css: "formula")
            when ISO::InlineFormula then render_element("span", render_inline(node), css: "formula")
            when ISO::NonNormativeNote then render_element("div", render_children(node), css: "note")
            when ISO::NonNormativeExample then render_element("div", render_children(node), css: "example")
            when NISO::DispQuote then render_element("blockquote", render_children(node))
            when ISO::ExtLink, ISO::Uri then render_link(href: node.xlink_href, text: inline_or_content(node))
            when Mml::V3::Math then node.to_xml
            else render_by_name(node)
            end
          end

          # Secondary dispatch on the (demodulized) model class name for
          # the long tail of elements that map onto plain markup.
          def render_by_name(node)
            case node.class.name.split("::").last
            when "TableWrap" then render_element("div", render_children(node), css: "table-wrap")
            when "Table" then render_element("table", render_children(node))
            when "Thead" then render_element("thead", render_children(node))
            when "Tbody" then render_element("tbody", render_children(node))
            when "Tr" then render_element("tr", render_children(node))
            when "Td" then render_element("td", render_inline(node))
            when "Th" then render_element("th", render_inline(node))
            when "Term" then render_element("dt", render_children(node))
            when "Def" then render_element("dd", render_children(node))
            when "Fig" then render_element("figure", render_children(node))
            when "Caption" then render_element("figcaption", render_children(node))
            when "List" then render_list(node)
            when "RefList" then render_element("div", render_children(node), css: "ref-list")
            when "Ref" then render_element("div", render_children(node), css: "ref")
            when "MixedCitation", "ElementCitation" then render_element("span", render_inline(node), css: "citation")
            when "Std" then render_element("span", render_inline(node), css: "std-ref")
            when "StdIdent" then render_element("span", render_inline(node), css: "std-ident")
            when "DocIdentifier", "DocIdent" then render_element("span", render_inline(node), css: "doc-id")
            when "CopyrightStatement" then render_element("span", render_inline(node), css: "copyright")
            when "Fn" then render_element("span", render_inline(node), css: "footnote")
            when "Xref" then render_xref(node)
            when "Break" then "<br/>"
            when "ProcessingMeta" then ""
            when *INLINE_TAGS.keys.map(&:name).map { |n| n.split("::").last } then render_inline_tag(node)
            else render_children(node)
            end
          end

          # ----------------------------------------------------------------
          # Walking
          # ----------------------------------------------------------------

          # Ordered children of a non-mixed container, using element_order
          # so content renders in document order. Repeated elements of a
          # collection appear as one element_order entry PER ITEM, so
          # collection items are consumed one entry at a time (index
          # counter per attribute); text nodes pass through (escaped).
          def render_children(node)
            return render_inline(node) if mixed_model?(node)

            mapping = element_attr_map(node)
            indices = Hash.new(0)
            node.element_order.filter_map do |entry|
              case entry.node_type
              when :text
                escape(entry.text_content.to_s)
              when :element
                attr = mapping[entry.name.to_s]
                next unless attr

                item = collection_item_at(node, attr, indices)
                next unless item

                rendered = render_node(item)
                rendered unless rendered.empty?
              end
            end.join
          end

          # The next unconsumed item of +attr+ on +node+: for a collection
          # attribute, the item at the per-attribute index (advanced on
          # each call); for a single-value attribute, the value itself.
          def collection_item_at(node, attr, indices)
            value = node.public_send(attr)
            return value unless value.is_a?(Array)

            item = value[indices[attr]]
            indices[attr] += 1
            item
          end

          # Mixed-content (inline) walk: strings and inline models in order.
          # Non-mixed models (block containers) route to the ordered walk.
          def render_inline(node)
            return render_children(node) unless mixed_model?(node)

            node.each_mixed_content.filter_map do |child|
              rendered = child.is_a?(String) ? escape(child) : render_node(child)
              rendered unless rendered.empty?
            end.join
          end

          # Whether the model's XML mapping declares mixed content
          # (interleaved text + elements), meaning each_mixed_content is
          # the correct walk.
          def mixed_model?(node)
            node.class.mappings_for(:xml, node.lutaml_register).mixed_content?
          end

          # element name → attribute name, per model class (cached).
          def element_attr_map(node)
            (@attr_maps ||= {})[node.class] ||= begin
              xml_mapping = node.class.mappings_for(:xml, node.lutaml_register)
              map = {}
              xml_mapping.mapping_elements_hash.each_value do |rule_or_array|
                Array(rule_or_array).each do |rule|
                  map[rule.name.to_s] = rule.to
                end
              end
              map
            end
          end

          # ----------------------------------------------------------------
          # Element emitters (via Liquid templates)
          # ----------------------------------------------------------------

          def render_element(tag, content, id: nil, css: nil)
            render_liquid("_element.html.liquid", {
                            "tag" => tag, "id" => id,
                            "css" => css, "content" => content
                          })
          end

          def render_inline_tag(node)
            tag = INLINE_TAGS[node.class]
            inner = render_inline(node)
            return render_element("span", inner, css: "small-caps") if tag == "span"

            render_element(tag, inner)
          end

          def render_list(node)
            tag = node.list_type == "order" ? "ol" : "ul"
            render_element(tag, render_children(node))
          end

          def render_graphic(node)
            render_liquid("_img.html.liquid", {
                            "src" => node.xlink_href.to_s,
                            "alt" => node.alttext.to_s,
                          })
          end

          def render_xref(node)
            rid = node.rid.to_s
            text = render_inline(node).strip
            text = "[#{rid}]" if text.empty?

            render_link(href: "##{rid}", text: text)
          end

          def render_link(href:, text:)
            render_liquid("_link.html.liquid", {
                            "href" => href.to_s, "text" => text
                          })
          end

          def render_meta(node)
            title = find_text(node, ["TitleWrap", "Title"])
            docid = find_text(node, %w[DocIdentifier DocIdent StdIdent
                                       StandardIdentification
                                       DocumentIdentification])
            return "" if title.empty? && docid.empty?

            render_liquid("_meta_header.html.liquid", {
                            "docid" => docid, "title" => title
                          })
          end

          # First non-empty plain text found under the node whose class
          # (demodulized) is one of +names+.
          def find_text(node, names)
            if names.include?(node.class.name.split("::").last)
              text = plain_text(node).gsub(/\s+/, " ").strip
              return text unless text.empty?
            end

            node.class.attributes.each_key do |attr|
              value = node.public_send(attr)
              Array(value).compact.each do |child|
                next unless child.is_a?(Lutaml::Model::Serializable)

                found = find_text(child, names)
                return found unless found.empty?
              end
            end
            ""
          end

          def plain_text(node)
            return node.to_s unless node.is_a?(Lutaml::Model::Serializable)

            if mixed_model?(node)
              node.each_mixed_content.map do |child|
                child.is_a?(String) ? child : plain_text(child)
              end.join
            else
              ordered_content_parts(node).map do |child|
                child.is_a?(String) ? child : plain_text(child)
              end.join
            end
          end

          # Ordered content parts (text nodes AND child items) of a
          # non-mixed container — used by plain_text so inter-element
          # whitespace is preserved for later normalization.
          def ordered_content_parts(node)
            mapping = element_attr_map(node)
            indices = Hash.new(0)
            node.element_order.filter_map do |entry|
              if entry.node_type == :text
                entry.text_content.to_s
              else
                attr = mapping[entry.name.to_s]
                next unless attr

                collection_item_at(node, attr, indices)
              end
            end
          end

          def inline_or_content(node)
            rendered = render_inline(node)
            rendered.empty? ? node.content.to_s : rendered
          end

          def escape(text)
            CGI.escapeHTML(text.to_s)
          end

          def render_liquid(template_name, assigns)
            template = @template_cache[template_name] ||= begin
              path = File.join(@templates_dir, template_name)
              Liquid::Template.parse(File.read(path), environment: @liquid_env)
            end
            template.render(assigns)
          end
        end
      end
    end
  end
end
