# frozen_string_literal: true

require "cgi"
require "liquid"
require "sts"

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        # STS XML → HTML renderer. Parses the input once into the sts-ruby
        # typed model and emits HTML through Liquid templates — no DOM
        # library, no XSLT engine.
        #
        # Architecture:
        #
        #   render
        #     ├── coerce_model      (XML string → Sts::IsoSts::Standard)
        #     ├── render_node       (model tree → fragment, via DISPATCH)
        #     └── assemble_document (fragment → full page via
        #                            templates/document.html.liquid with
        #                            assets/sts.css and the OIML logo)
        #
        # Element markup lives in templates/ and is overridable per
        # organization with Ruby.new(templates_dir:, assets_dir:) — no
        # code changes needed.
        class Ruby
          TEMPLATES_DIR = File.expand_path("templates", __dir__)
          ASSETS_DIR = File.expand_path("assets", __dir__)

          ISO = ::Sts::IsoSts
          NISO = ::Sts::NisoSts

          # demodulized model class name → handler method. Anything not
          # listed renders its children transparently (see #render_children).
          DISPATCH = {
            "IsoMeta" => :meta, "RegMeta" => :meta, "NatMeta" => :meta,
            "Body" => :main,
            "Sec" => :section, "App" => :section, "TermSec" => :section,
            "Label" => :label,
            "Title" => :title,
            "Paragraph" => :paragraph,
            "List" => :list, "ListItem" => :list_item,
            "DefList" => :def_list, "Term" => :term, "Def" => :def_item,
            "TableWrap" => :table_wrap, "Table" => :table,
            "Thead" => :thead, "Tbody" => :tbody, "Tr" => :tr,
            "Td" => :td, "Th" => :th,
            "Fig" => :figure, "Caption" => :caption, "Graphic" => :graphic,
            "DispFormula" => :disp_formula, "InlineFormula" => :inline_formula,
            "NonNormativeNote" => :note, "NonNormativeExample" => :example,
            "DispQuote" => :quote,
            "RefList" => :ref_list, "Ref" => :ref,
            "MixedCitation" => :citation, "ElementCitation" => :citation,
            "Std" => :std, "StdIdent" => :std_ident,
            "Originator" => :originator,
            "DocIdentifier" => :doc_id, "DocIdent" => :doc_id,
            "CopyrightStatement" => :copyright,
            "Fn" => :fn, "Xref" => :xref,
            "ExtLink" => :ext_link, "Uri" => :ext_link,
            "Break" => :brk, "ProcessingMeta" => :skip
          }.freeze

          # Inline phrase-level elements → HTML tag (constant-keyed).
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

          META_ID_NAMES = %w[DocIdentifier DocIdent StdIdent
                             StandardIdentification
                             DocumentIdentification].freeze

          def initialize(templates_dir: nil, assets_dir: nil)
            @templates_dir = templates_dir || TEMPLATES_DIR
            @assets_dir = assets_dir || ASSETS_DIR
            @liquid_env = Liquid::Environment.new
            @liquid_env.file_system = Liquid::LocalFileSystem.new(@templates_dir)
            @template_cache = {}
            @mapping_cache = Hash.new { |h, klass| h[klass] = build_mapping(klass) }
            @toc = []
            @depth = 0
          end

          # Render +model_or_xml+. With +full_document: true+ (default)
          # the fragment is assembled into a complete branded page;
          # with +full_document: false+ the bare fragment is returned.
          def render(model_or_xml, full_document: true)
            model = coerce_model(model_or_xml)
            @assemble = full_document
            @toc = []
            @depth = 0
            body = render_node(model)
            return body unless full_document

            assemble_document(body, model)
          end

          private

          attr_reader :templates_dir, :assets_dir

          def coerce_model(input)
            return input if input.is_a?(Lutaml::Model::Serializable)

            ::Sts::IsoSts::Standard.from_xml(input.to_s)
          end

          # --------------------------------------------------------------
          # Dispatch
          # --------------------------------------------------------------

          def render_node(node)
            case node
            when String then escape(node)
            when Mml::V3::Math then node.to_xml
            when *INLINE_TAGS.keys then render_inline_tag(node)
            else
              handler = DISPATCH[node.class.name.split("::").last]
              handler ? send(handler, node) : render_children(node)
            end
          end

          # --------------------------------------------------------------
          # Handlers
          # --------------------------------------------------------------

          def main(node) = render_element("main", render_children(node))

          def section(node)
            sec_id = section_id(node)
            register_toc(node, sec_id)
            @depth += 1
            @current_section_id = sec_id
            inner = render_children(node)
            render_element("section", inner, id: sec_id)
          ensure
            @depth -= 1
          end

          # Sections built without an id (e.g. front-matter sections)
          # get a slug from their title so they are linkable and can
          # appear in the TOC.
          def section_id(node)
            return node.id if node.class.method_defined?(:id) && node.id

            title_node = find_child(node, "Title")
            return nil unless title_node

            plain_text(title_node).gsub(/\s+/, " ").strip
              .downcase.gsub(/[^a-z0-9]+/, "-")
              .gsub(/\A-|-\z/, "")
          end

          # Records the section in the interactive table of contents.
          # Apps are sections too; their titles come from the same walk.
          def register_toc(node, sec_id)
            title_node = find_child(node, "Title")
            return unless sec_id && title_node

            @toc << { id: sec_id, title: plain_text(title_node).gsub(/\s+/, " ").strip,
                      depth: @depth }
          end

          # First direct child model whose demodulized class name matches.
          def find_child(node, demodulized_name)
            return nil unless node.class.method_defined?(:title)

            title = node.title
            return title if title && title.class.name.split("::").last == demodulized_name

            nil
          end

          def label(node) = render_element("span", render_inline(node), css: "label")

          def title(node)
            return render_element("em", render_inline(node)) if @in_std

            level = (1 + @depth).clamp(2, 4)
            anchor = if @current_section_id
                       %(<a class="h-anchor" href="##{@current_section_id}" aria-label="Link to this section">§</a>)
                     else
                       ""
                     end
            render_element("h#{level}", render_inline(node) + anchor)
          end

          def paragraph(node) = render_element("p", render_inline(node), id: node.id)

          def list(node)
            tag = node.list_type == "order" ? "ol" : "ul"
            render_element(tag, render_children(node))
          end

          def list_item(node) = render_element("li", render_children(node))

          def def_list(node) = render_element("dl", render_children(node))

          def term(node) = render_element("dt", render_children(node))

          def def_item(node) = render_element("dd", render_children(node))

          def table_wrap(node) = render_element("div", render_children(node), css: "table-wrap")

          def table(node) = render_element("table", render_children(node))

          def thead(node) = render_element("thead", render_children(node))

          def tbody(node) = render_element("tbody", render_children(node))

          def tr(node) = render_element("tr", render_children(node))

          def td(node) = render_element("td", render_children(node))

          def th(node) = render_element("th", render_children(node))

          def figure(node) = render_element("figure", render_children(node))

          def caption(node) = render_element("figcaption", render_children(node))

          def graphic(node)
            render_liquid("_img.html.liquid", {
                            "src" => node.xlink_href.to_s,
                            "alt" => node.alttext.to_s,
                          })
          end

          def disp_formula(node) = render_element("div", render_inline(node), css: "formula")

          def inline_formula(node) = render_element("span", render_inline(node), css: "formula")

          def note(node) = render_element("div", render_children(node), css: "note")

          def example(node) = render_element("div", render_children(node), css: "example")

          def quote(node) = render_element("blockquote", render_children(node))

          def ref_list(node) = render_element("div", render_children(node), css: "ref-list")

          def ref(node) = render_element("div", render_children(node), css: "ref")

          def citation(node) = render_element("span", render_inline(node), css: "citation")

          # <std> inside a bibliography ref: keep everything inline —
          # titles become <em>, never headings.
          def std(node)
            @in_std = true
            render_element("span", render_inline(node), css: "std")
          ensure
            @in_std = false
          end

          def std_ident(node) = render_element("span", render_inline(node), css: "std-ident")

          # <originator> inside std-ref: separated, quieter.
          def originator(node) = render_element("span", render_inline(node), css: "originator")

          def doc_id(node) = render_element("span", render_inline(node), css: "doc-id")

          def copyright(node) = render_element("span", render_inline(node), css: "copyright")

          def fn(node) = render_element("span", render_inline(node), css: "footnote")

          def ext_link(node)
            render_link(href: node.xlink_href, text: inline_or_content(node))
          end

          def xref(node)
            rid = node.rid.to_s
            text = render_inline(node).strip
            text = "[#{rid}]" if text.empty?

            render_link(href: "##{rid}", text: text)
          end

          def brk(_node) = "<br/>"

          def skip(_node) = ""

          def meta(node)
            return "" if @assemble

            title = find_text(node, ["TitleWrap", "Title"])
            docid = find_text(node, META_ID_NAMES)
            return "" if title.empty? && docid.empty?

            render_liquid("_meta_header.html.liquid", {
                            "docid" => docid, "title" => title
                          })
          end

          def render_inline_tag(node)
            tag = INLINE_TAGS[node.class]
            inner = render_inline(node)
            return render_element("span", inner, css: "small-caps") if tag == "span"

            render_element(tag, inner)
          end

          # --------------------------------------------------------------
          # Walking (document-order traversal of the typed model)
          # --------------------------------------------------------------

          # Children of a non-mixed container in document order.
          # Repeated elements of a collection appear as one element_order
          # entry PER ITEM, so collection items are consumed one entry at
          # a time (per-attribute index counters).
          def render_children(node)
            return render_inline(node) if mixed_model?(node)

            mapping = @mapping_cache[node.class][:elements]
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

          # Mixed-content (inline) walk; non-mixed models route back to
          # the ordered walk.
          def render_inline(node)
            return render_children(node) unless mixed_model?(node)

            node.each_mixed_content.filter_map do |child|
              rendered = child.is_a?(String) ? escape(child) : render_node(child)
              rendered unless rendered.empty?
            end.join
          end

          def mixed_model?(node)
            @mapping_cache[node.class][:mixed]
          end

          # element name → attribute name + mixed-content flag, per model
          # class (cached).
          def build_mapping(klass)
            return { elements: {}, mixed: false } unless klass.respond_to?(:mappings_for)

            instance = klass.allocate
            xml_mapping = klass.mappings_for(:xml, instance.lutaml_register)
            elements = {}
            xml_mapping.mapping_elements_hash.each_value do |rule_or_array|
              Array(rule_or_array).each { |rule| elements[rule.name.to_s] = rule.to }
            end
            { elements: elements, mixed: xml_mapping.mixed_content? }
          rescue Lutaml::Model::Error
            { elements: {}, mixed: false }
          end

          def collection_item_at(node, attr, indices)
            value = node.public_send(attr)
            return value unless value.is_a?(Array)

            item = value[indices[attr]]
            indices[attr] += 1
            item
          end

          # --------------------------------------------------------------
          # Document assembly (full page)
          # --------------------------------------------------------------

          def assemble_document(body, model)
            meta = meta_info(model)
            render_liquid("document.html.liquid", {
                            "lang" => "en",
                            "title" => meta[:title],
                            "css" => stylesheet,
                            "logo" => logo_svg,
                            "docid" => meta[:docid],
                            "toc" => toc_html,
                            "content" => body,
                            "js" => javascript,
                          })
          end

          # Flat TOC list with depth classes (indented via CSS); consumed
          # by the scroll-spy script in the page.
          def toc_html
            return "" if @toc.empty?

            items = @toc.map do |entry|
              %(<li class="toc-d#{entry[:depth]}"><a href="##{entry[:id]}">#{escape(entry[:title])}</a></li>)
            end.join
            %(<nav id="toc" aria-label="Contents"><p class="toc-heading">Contents</p><ol class="toc-list">#{items}</ol></nav>)
          end

          def meta_info(model)
            meta_node = find_meta_node(model)
            return { title: "", docid: "" } unless meta_node

            { title: find_text(meta_node, ["TitleWrap", "Title"]),
              docid: find_text(meta_node, META_ID_NAMES) }
          end

          # First meta block (iso-meta / std-meta / reg-meta / nat-meta)
          # found under the document front matter.
          def find_meta_node(node)
            name = node.class.name.split("::").last
            return node if %w[IsoMeta StdMeta RegMeta NatMeta].include?(name)
            return nil unless node.is_a?(Lutaml::Model::Serializable)

            node.class.attributes.each_value do |attr_def|
              value = node.public_send(attr_def.name)
              Array(value).compact.each do |child|
                next unless child.is_a?(Lutaml::Model::Serializable)

                found = find_meta_node(child)
                return found if found
              end
            end
            nil
          end

          def stylesheet
            @stylesheet ||= File.read(File.join(assets_dir, "sts.css"))
          end

          def logo_svg
            @logo_svg ||= File.read(File.join(assets_dir, "oiml-logo.svg"))
              .sub(/\A<\?xml[^?]*\?>\s*/, "")
          end

          # Page behaviour: scroll-spy TOC, mobile TOC drawer, back-to-top,
          # heading-anchor copy. Vanilla JS, no dependencies.
          def javascript
            @javascript ||= File.read(File.join(assets_dir, "page.js"))
          end

          # --------------------------------------------------------------
          # Text extraction
          # --------------------------------------------------------------

          # First non-empty plain text under the node whose demodulized
          # class name is in +names+.
          def find_text(node, names)
            if names.include?(node.class.name.split("::").last)
              text = plain_text(node).gsub(/\s+/, " ").strip
              return text unless text.empty?
            end

            node.class.attributes.each_value do |attr_def|
              value = node.public_send(attr_def.name)
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

            children = mixed_model?(node) ? node.each_mixed_content.to_a : ordered_content_parts(node)
            children.map do |child|
              child.is_a?(String) ? child : plain_text(child)
            end.join
          end

          def ordered_content_parts(node)
            mapping = @mapping_cache[node.class][:elements]
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

          # --------------------------------------------------------------
          # Liquid emitters
          # --------------------------------------------------------------

          def render_element(tag, content, id: nil, css: nil)
            render_liquid("_element.html.liquid", {
                            "tag" => tag, "id" => id,
                            "css" => css, "content" => content
                          })
          end

          def render_link(href:, text:)
            render_liquid("_link.html.liquid", {
                            "href" => href.to_s, "text" => text
                          })
          end

          def render_liquid(template_name, assigns)
            template = @template_cache[template_name] ||= begin
              path = File.join(templates_dir, template_name)
              # chomp: template files must not contribute their own
              # trailing newline into the output (it surfaces as a
              # visible space between inline elements)
              Liquid::Template.parse(File.read(path).chomp, environment: @liquid_env)
            end
            template.render(assigns)
          end

          def escape(text)
            CGI.escapeHTML(text.to_s)
          end
        end
      end
    end
  end
end
