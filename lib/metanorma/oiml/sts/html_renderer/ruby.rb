# frozen_string_literal: true

require "nokogiri"

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        # Ruby fallback renderer: hand-rolled semantic HTML from STS XML.
        class Ruby
          def render(model_or_xml)
            xml = model_or_xml.respond_to?(:to_xml) ? model_or_xml.to_xml : model_or_xml
            doc = Nokogiri::XML(xml)
            render_node(doc.root)
          end

          private

          def render_node(node)
            return "" unless node

            case node.name
            when "standard", "adoption"
              render_children(node)
            when "front"
              render_children(node)
            when "body"
              element("main", render_children(node))
            when "back"
              render_children(node)
            when "iso-meta", "std-meta", "reg-meta"
              render_meta(node)
            when "sec", "app"
              element("section", render_children(node))
            when "label"
              element("span", node.text, class: "label")
            when "title"
              element("h2", node.text)
            when "p"
              element("p", render_inline(node))
            when "list"
              tag = node["list-type"] == "order" ? "ol" : "ul"
              element(tag, render_children(node))
            when "list-item"
              element("li", render_children(node))
            when "def-list"
              element("dl", render_children(node))
            when "def-item"
              render_children(node)
            when "term"
              element("dt", render_inline(node))
            when "def"
              element("dd", render_children(node))
            when "table-wrap"
              element("div", render_children(node), class: "table-wrap")
            when "table"
              element("table", render_children(node))
            when "thead"
              element("thead", render_children(node))
            when "tbody"
              element("tbody", render_children(node))
            when "tr"
              element("tr", render_children(node))
            when "td"
              element("td", render_inline(node))
            when "th"
              element("th", render_inline(node))
            when "fig"
              element("figure", render_children(node))
            when "caption"
              element("figcaption", render_inline(node))
            when "graphic"
              %(<img src="#{node['xlink:href']}" alt="#{node['alttext'] || ''}"/>)
            when "disp-formula"
              element("div", render_inline(node), class: "formula")
            when "inline-formula"
              element("span", render_inline(node), class: "formula")
            when "italic"
              element("em", node.text)
            when "bold"
              element("strong", node.text)
            when "monospace"
              element("code", node.text)
            when "sub"
              element("sub", node.text)
            when "sup"
              element("sup", node.text)
            when "ext-link", "uri"
              %(<a href="#{node['xlink:href']}">#{node.text}</a>)
            when "xref"
              rid = node["rid"].to_s
              text = node.text.strip
              text = "[#{rid}]" if text.empty?
              %(<a href="##{rid}">#{text}</a>)
            when "fn"
              element("span", render_inline(node), class: "footnote")
            when "non-normative-note", "normative-note"
              element("div", render_children(node), class: "note")
            when "non-normative-example", "normative-example"
              element("div", render_children(node), class: "example")
            when "disp-quote"
              element("blockquote", render_children(node))
            when "ref-list"
              element("div", render_children(node), class: "ref-list")
            when "ref"
              element("div", render_children(node), class: "ref")
            when "element-citation", "mixed-citation"
              element("span", render_inline(node), class: "citation")
            when "std"
              element("span", render_inline(node), class: "std-ref")
            when "std-ident"
              element("span", render_inline(node), class: "std-ident")
            when "title-wrap"
              render_children(node)
            when "doc-identifier", "doc-ident"
              element("span", node.text, class: "doc-id")
            when "permissions"
              render_children(node)
            when "copyright-statement"
              element("span", node.text, class: "copyright")
            when "app-group"
              render_children(node)
            when "processing-meta"
              ""
            when "math"
              node.to_html
            when "text"
              node.text
            else
              render_children(node)
            end
          end

          def render_children(node)
            node.children.map { |child| render_node(child) }.join
          end

          def render_inline(node)
            node.children.map { |child| render_node(child) }.join
          end

          def render_meta(node)
            title = node.at_xpath(".//title-wrap/main")&.text ||
                    node.at_xpath(".//title")&.text ||
                    node.at_xpath(".//title-group/main")&.text
            docid = node.at_xpath(".//std-ident")&.text ||
                    node.at_xpath(".//doc-identifier | .//doc-ident/doc-identifier")&.text
            parts = []
            parts << %(<span class="doc-id">#{docid}</span>) if docid
            parts << %(<span class="title">#{title}</span>) if title
            element("header", parts.join) if parts.any?
          end

          def element(tag, content, **attrs)
            attr_str = attrs.map { |k, v| %( #{k}="#{v}") }.join
            %(<#{tag}#{attr_str}>#{content}</#{tag}>)
          end
        end
      end
    end
  end
end
