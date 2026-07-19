# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ParagraphTransformer < Base
          PRESENTATION_CLASSES = %w[
            FmtTitleElement FmtXrefLabelElement FmtNameElement FmtFnLabelElement
            FmtAnnotationStartElement FmtAnnotationEndElement FmtConceptElement
            LocalizedString LocalizedStrings FmtVal AsciiMath
            BrElement TabElement Bookmark
          ].freeze

          def transform(source_para)
            id_val = nil
            if source_para.is_a?(Lutaml::Model::Serializable) && source_para.class.method_defined?(:id)
              id_val = source_para.id
            end

            @seen_nodes = {}
            entries = []
            current_text = nil
            flush_text = lambda do
              return if current_text.nil?
              entries << [:text, clean_text(current_text)]
              current_text = nil
            end

            walk_inline(source_para) do |kind, node, text|
              case kind
              when :text
                current_text = (current_text || "") + text
              when :bold
                flush_text.call
                entries << [:bold, ModelBuilder.bold(content: [text])]
              when :italic
                flush_text.call
                entries << [:italic, ModelBuilder.italic(content: [text])]
              when :sub
                flush_text.call
                entries << [:sub, ModelBuilder.sub(content: [text])]
              when :sup
                flush_text.call
                entries << [:sup, ModelBuilder.sup(content: [text])]
              when :tt
                flush_text.call
                entries << [:tt, ModelBuilder.monospace(content: [text])]
              when :stem
                formula = build_inline_formula(node)
                if formula
                  flush_text.call
                  entries << [:inline_formula, formula]
                end
              when :xref
                x = build_xref(node)
                if x
                  flush_text.call
                  entries << [:xref, x]
                end
              when :link
                l = build_link(node)
                if l
                  flush_text.call
                  entries << [:ext_link, l]
                end
              when :eref
                if text && !text.empty?
                  current_text = (current_text || "") + text
                end
              when :concept
                if text && !text.empty?
                  current_text = (current_text || "") + text
                end
              end
            end
            flush_text.call

            ::Sts::IsoSts::Paragraph.new(id: id_val) do |p|
              entries.each do |kind, value|
                case kind
                when :text then p.content value
                when :bold then p.bold value
                when :italic then p.italic value
                when :sub then p.sub value
                when :sup then p.sup value
                when :tt then p.monospace value
                when :inline_formula then p.inline_formula value
                when :xref then p.xref value
                when :ext_link then p.ext_link value
                end
              end
            end
          end

          private

          def walk_inline(obj, &block)
            return unless obj.class.method_defined?(:each_mixed_content)

            nodes = obj.each_mixed_content.to_a
            nodes.each_with_index do |node, index|
              following = nodes[index + 1]
              if semantic_with_mirror?(node, following)
                emit_mirror(node, following, &block)
                next
              end

              walk_node(node, &block)
            end
          end

          # A semantic element (<link>, <eref>, ...) immediately followed
          # by its <semx> presentation mirror (semx@source == element@id):
          # the pair is emitted as ONE unit — the mirror carries the
          # renderable form, the semantic original lends its kind
          # (style/type) when the mirror doesn't declare one (NISO STS
          # @ref-type maps from Metanorma's @type/@style).
          def semantic_with_mirror?(node, following)
            return false if node.is_a?(String)
            return false unless following.is_a?(Metanorma::Document::Components::Inline::SemxElement)
            return false unless following.class.method_defined?(:source) && following.source

            node.class.method_defined?(:id) && node.id && node.id == following.source
          end

          def emit_mirror(node, mirror, &block)
            @mirror_style = node_style(node)
            walk_node(mirror, &block)
          ensure
            @mirror_style = nil
          end

          def node_style(node)
            %i[style type].each do |attr|
              next unless node.class.method_defined?(attr)

              val = node.public_send(attr).to_s
              return val unless val.empty?
            end
            nil
          end

          # Walks a single node yielded by each_mixed_content. Recurses
          # into SemxElement wrappers so fmt-preferred / fmt-concept trees
          # (which wrap content in semx) walk the same way as body
          # paragraphs (which usually have direct inline children).
          # Semx mirrors inline children into named attributes as well as
          # its mixed content — @seen_nodes prevents double-yielding.
          def walk_node(node, &block)
            if node.is_a?(String)
              yield(:text, node, node)
              return
            end
            return if @seen_nodes[node.object_id]

            @seen_nodes[node.object_id] = true

            class_name = node.class.name&.split("::")&.last
            return if PRESENTATION_CLASSES.include?(class_name)
            return if presentation_span?(node)

            case class_name
            when "SemxElement"
              # Mixed content first; named child attributes only as a
              # fallback for fmt trees that store inlines there (the two
              # views mirror each other — walking both duplicates links.
              yield_count = 0
              counting = lambda do |kind, node, text|
                yield_count += 1
                yield(kind, node, text)
              end
              walk_inline(node, &counting)
              walk_semx_named_children(node, &counting) if yield_count.zero?
            when "EmRawElement", "EmElement"
              yield(:italic, node, text_of(node))
            when "StrongRawElement", "StrongElement"
              yield(:bold, node, text_of(node))
            when "SubElement"
              yield(:sub, node, text_of(node))
            when "SupElement"
              yield(:sup, node, text_of(node))
            when "TtElement", "MonospaceElement"
              yield(:tt, node, text_of(node))
            when "StemInlineElement", "StemBlockElement", "FmtStemElement"
              yield(:stem, node, nil)
            when "AsciimathElement"
              nil
            when "SpanElement"
              span_text = RenderedTextExtractor.text_of(node)
              yield(:text, node, span_text) if span_text && !span_text.empty?
            when "LinkElement"
              yield(:link, node, text_of(node))
            when "XrefElement"
              return
            when "FmtXrefElement", "FmtErefElement"
              yield(:xref, node, RenderedTextExtractor.text_of(node))
            when "ErefElement"
              yield(:eref, node, eref_text(node))
            when "ConceptElement"
              yield(:concept, node, concept_text(node))
            else
              # Never silently drop content: unhandled inline classes
              # degrade to their extracted text.
              fallback_text = RenderedTextExtractor.text_of(node)
              yield(:text, node, fallback_text) if fallback_text && !fallback_text.empty?
            end
          end

          # Named child attributes on SemxElement that store inline
          # content (strong_child, em_child, etc.). Walked in addition
          # to the mixed-content collection for fmt-preferred / fmt-concept
          # trees that store inlines in named attributes.
          SEMX_NAMED_CHILDREN = %i[
            stem_child strong em sup sub tt underline strike
            preferred_child name_child title_child
            verbal_definition_child definition_child
            concept_child fn_child link_child
          ].freeze

          def walk_semx_named_children(semx, &block)
            SEMX_NAMED_CHILDREN.each do |attr|
              next unless semx.class.method_defined?(attr)
              val = semx.public_send(attr)
              next if val.nil?
              Array(val).each { |v| walk_node(v, &block) }
            end
          end

          # MathML passthrough: parse the stem's <math> into Mml::V3::Math
          # and wrap it in an InlineFormula. Delegates to MathmlBuilder
          # so paragraph/table/formula transformers stay DRY. Returns nil
          # when the stem has no parseable MathML — caller silently drops.
          def build_inline_formula(stem_node)
            ::Metanorma::Oiml::Sts::MathmlBuilder.inline_formula_from_stem(stem_node)
          end

          def build_xref(node)
            rid = nil
            [:target, :refid, :to].each do |attr|
              next unless node.class.method_defined?(attr)
              val = node.public_send(attr)
              rid = val if val.is_a?(String) && !val.empty?
              break if rid
            end
            return nil unless rid

            visible = xref_visible_text(node, rid)
            ModelBuilder.xref(rid: rid, ref_type: ref_type_for(node), value: visible)
          end

          def xref_visible_text(node, rid)
            explicit = text_of(node)
            return explicit unless explicit.empty?
            case rid
            when /\Asec-(.+)\z/, /\Afig-(.+)\z/, /\Atable-(.+)\z/, /\Afn-(.+)\z/
              Regexp.last_match(1)
            else
              rid
            end
          end

          def ref_type_for(node)
            style = node.style if node.class.method_defined?(:style)
            style = style.to_s if style
            style = @mirror_style if (style.nil? || style.empty?) && @mirror_style
            case style
            when "clause", "section" then "sec"
            when "table" then "table"
            when "figure", "fig" then "fig"
            when "fn", "footnote" then "fn"
            else "other"
            end
          end

          def build_link(node)
            href = nil
            [:target, :href].each do |attr|
              next unless node.class.method_defined?(attr)
              val = node.public_send(attr)
              href = val if val.is_a?(String) && !val.empty?
              break if href
            end
            return nil unless href

            visible = href.start_with?("mailto:") ? href.sub("mailto:", "") : link_text(node)
            ModelBuilder.ext_link(xlink_href: href, content: [visible])
          end

          def link_text(node)
            c = node.content if node.class.method_defined?(:content)
            c = Array(c) unless c.is_a?(Array)
            joined = c.map(&:to_s).join.strip
            joined.empty? ? text_of(node) : joined
          end

          def eref_text(node)
            citeas = node.citeas if node.class.method_defined?(:citeas)
            return citeas.to_s if citeas && !citeas.to_s.empty?
            text_of(node)
          end

          def concept_text(node)
            renderterm = Array(node.renderterm).first.to_s if node.class.method_defined?(:renderterm)
            xref_node = Array(node.xref).first if node.class.method_defined?(:xref)
            return renderterm unless xref_node

            rid = xref_node.target if xref_node.class.method_defined?(:target)
            autonum = source.term_autonum_for(rid) if rid
            return "#{renderterm} (#{autonum})" if autonum && !autonum.empty?
            "#{renderterm} (#{rid})"
          end

          def presentation_span?(node)
            return false unless node.is_a?(Metanorma::Document::Components::Inline::SpanElement)
            cls = node.class_attr
            cls.is_a?(String) && %w[fmt-autonum-delim fmt-caption-delim citesec citefig citetbl stdpublisher stddocNumber stdyear].any? { |c| cls.include?(c) }
          end

          def text_of(obj)
            return obj.to_s if obj.is_a?(String)
            return "" unless obj
            RenderedTextExtractor.text_of(obj)
          end

          def clean_text(text)
            text.to_s.gsub(/link:mailto:([^\s\[]+)/, '\1').gsub(/link:([^\s\[]+)/, '\1')
          end
        end
      end
    end
  end
end
