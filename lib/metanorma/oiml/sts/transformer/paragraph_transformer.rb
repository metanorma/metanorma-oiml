# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class ParagraphTransformer < Base
          # Walks the typed ParagraphBlock's mixed content in document order
          # via `each_mixed_content`. Uses lutaml-model's builder DSL so the
          # resulting Paragraph preserves cross-type inline ordering via the
          # internal `element_order` log (e.g. text → italic → text → xref
          # serializes correctly).
          def transform(source_para)
            id_value = source_para.id if source_para.respond_to?(:id) && source_para.id

            entries = []
            current_text = nil

            flush_text = lambda do
              return if current_text.nil?
              entries << [:text, current_text]
              current_text = nil
            end

            each_inline(source_para) do |kind, node, text|
              case kind
              when :text
                current_text = (current_text || "") + clean_text(text)
              when :bold
                flush_text.call
                entries << [:bold, ::Sts::IsoSts::Bold.new(content: [text])]
              when :italic
                flush_text.call
                entries << [:italic, ::Sts::IsoSts::Italic.new(content: [text])]
              when :sub
                flush_text.call
                entries << [:sub, ::Sts::IsoSts::Sub.new(content: [text])]
              when :sup
                flush_text.call
                entries << [:sup, ::Sts::IsoSts::Sup.new(content: [text])]
              when :monospace
                flush_text.call
                entries << [:monospace, ::Sts::IsoSts::Monospace.new(content: [text])]
              when :underline
                flush_text.call
                entries << [:underline, ::Sts::IsoSts::Underline.new(content: [text])]
              when :strike
                flush_text.call
                entries << [:strike, ::Sts::IsoSts::Strike.new(content: [text])]
              when :link
                l = build_link(node)
                if l
                  flush_text.call
                  entries << [:ext_link, l]
                end
              when :xref
                x = build_xref(node)
                if x
                  flush_text.call
                  entries << [:xref, x]
                end
              when :eref
                if text && !text.empty?
                  current_text = (current_text || "") + text
                end
              when :fn
                f = build_fn(node)
                if f
                  flush_text.call
                  entries << [:fn, f]
                end
              when :stem
                if text && !text.empty?
                  current_text = (current_text || "") + text
                end
              when :note
                n = build_note(node)
                if n
                  flush_text.call
                  entries << [:non_normative_note, n]
                end
              when :concept
                if text && !text.empty?
                  current_text = (current_text || "") + text
                end
              end
            end
            flush_text.call

            build_paragraph_from_entries(id_value, entries)
          end

          def build_paragraph_from_entries(id_value, entries)
            ::Sts::IsoSts::Paragraph.new(id: id_value) do |p|
              entries.each do |kind, value|
                case kind
                when :text then p.content value
                when :bold then p.bold value
                when :italic then p.italic value
                when :sub then p.sub value
                when :sup then p.sup value
                when :monospace then p.monospace value
                when :underline then p.underline value
                when :strike then p.strike value
                when :ext_link then p.ext_link value
                when :xref then p.xref value
                when :fn then p.fn value
                when :non_normative_note then p.non_normative_note value
                end
              end
            end
          end

          private

          def each_inline(obj)
            return unless obj.respond_to?(:each_mixed_content)

            # Build id→rendered_text map from the paragraph's fmt_stem
            # collection. The fmt-stem's semx.source matches the semantic
            # stem's id, giving us reliable pairing (vs positional).
            rendered_map = build_rendered_stem_map(obj)

            obj.each_mixed_content do |node|
              if node.is_a?(String)
                yield(:text, node, node)
                next
              end

              class_name = node.class.name&.split("::")&.last
              next if PRESENTATION_CLASS_NAMES.include?(class_name)
              next if presentation_span?(node)

              case class_name
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
              when "LinkElement"
                yield(:link, node, text_of(node))
              when "XrefElement"
                yield(:xref, node, text_of(node))
              when "ErefElement"
                yield(:eref, node, eref_text(node))
              when "FnElement"
                yield(:fn, node, text_of(node))
              when "StemInlineElement", "StemBlockElement"
                # Prefer rendered text from the matching fmt-stem (which
                # has decimal commas, thousands separators). Fall back
                # to the semantic stem's own MathML.
                text = rendered_map[node.id]
                if text.nil? || text.empty?
                  text = stem_text_from_node(node)
                end
                yield(:stem, node, text)
              when "FmtStemElement"
                nil
              when "SpanElement"
                # Content spans (e.g. style="text-indent:...") wrap real
                # text/stem content. Walk via RenderedTextExtractor and
                # yield as text.
                span_text = ::Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor.text_of(node)
                yield(:text, node, span_text) if span_text && !span_text.empty?
              when "NoteBlock"
                yield(:note, node, "")
              when "ConceptElement"
                yield(:concept, node, concept_text(node))
              end
            end
          end

          def build_note(note_node)
            paragraphs = note_node.respond_to?(:content) ? Array(note_node.content) : []
            return nil if paragraphs.empty?

            sts_paragraphs = paragraphs.each_with_index.map do |p, i|
              if p.is_a?(String)
                text = i.zero? ? "Note  #{p}" : p
                ::Sts::IsoSts::Paragraph.new(content: [text])
              else
                para = paragraph_transformer.transform(p)
                if i.zero?
                  existing = para.content.to_a
                  para.content = ["Note  #{existing.first || ''}"] + existing[1..]
                end
                para
              end
            end
            ::Sts::IsoSts::NonNormativeNote.new(paragraph: sts_paragraphs)
          end

          def note_text(note_node)
            paragraphs = note_node.respond_to?(:content) ? Array(note_node.content) : []
            return "" if paragraphs.empty?

            text = paragraphs.map { |p| text_of(p) }.reject(&:empty?).join(" ")
            "Note: #{text}"
          end

          # ConceptElement renders as "{renderterm} ({autonum})".
          # The autonum must be looked up from the target term's
          # fmt-xref-label, matching Metanorma HTML output.
          def concept_text(node)
            renderterm = Array(node.renderterm).first.to_s
            xref_node = Array(node.xref).first
            return renderterm unless xref_node

            rid = (xref_node.target rescue nil) || (xref_node.to rescue nil)
            autonum = context.source.term_autonum_for(rid) if rid
            return "#{renderterm} (#{autonum})" if autonum && !autonum.empty?

            "#{renderterm} (#{rid})"
          end

          PRESENTATION_CLASS_NAMES = %w[
            FmtTitleElement
            FmtXrefLabelElement
            FmtNameElement
            FmtFnLabelElement
            FmtAnnotationStartElement
            FmtAnnotationEndElement
            FmtConceptElement
            SemxElement
            LocalizedString
            LocalizedStrings
            FmtVal
            AsciiMath
            BrElement
            TabElement
            Bookmark
          ].freeze

          # SpanElement class_attr values that are pure presentation
          # chrome (delimiters, autonum wrappers). Spans WITHOUT these
          # class_attr values contain real content and must be processed.
          PRESENTATION_SPAN_CLASSES = %w[
            fmt-autonum-delim
            fmt-caption-delim
            fmt-label-delim
            fmt-comma
            fmt-conn
            fmt-enum-comma
            citesec
            citefig
            citetbl
            stdpublisher
            stddocNumber
            stddocPartNumber
            stdyear
            fmt-element-name
            fmt-xref-container
          ].freeze

          def text_of(obj)
            return obj.to_s if obj.is_a?(String)
            return "" unless obj

            val = nil
            begin
              val = obj.text
            rescue StandardError
              val = nil
            end
            return "" if val.nil?

            if val.is_a?(Array)
              val.map(&:to_s).join.strip
            else
              val.to_s.strip
            end
          end

          def stem_text(node)
            # Delegate to RenderedTextExtractor so math content (decimal
            # commas, thousands separators, Unicode operators) is preserved
            # consistently. Returns padded text (with surrounding spaces)
            # matching MN HTML browser rendering of math content.
            ::Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor.stem_text_padded(node)
          end

          def stem_text_from_node(node)
            stem_text(node)
          end

          # Extracts rendered text from a FmtStemElement (the presentation
          # form of a stem). The fmt-stem wraps a SemxElement which
          # contains a MathElement with the rendered MathML (which may
          # have decimal commas, thousands separators). Walks via
          # RenderedTextExtractor which handles MathElement → MathML text.
          # Builds a map from semantic stem id → rendered text (extracted
          # from the paragraph's fmt_stem collection). The fmt-stem's
          # semx.source attribute matches the semantic stem's id.
          # Returns an empty hash if the paragraph has no fmt_stem or
          # the attribute isn't accessible.
          def build_rendered_stem_map(paragraph)
            fmt_stems = paragraph.fmt_stem if paragraph.class.method_defined?(:fmt_stem)
            return {} unless fmt_stems.is_a?(Array)

            map = {}
            fmt_stems.each do |fs|
              semx_arr = Array(fs.semx)
              semx_arr.each do |semx|
                source_id = semx.source if semx.class.method_defined?(:source)
                next unless source_id.is_a?(String) && !source_id.empty?

                text = fmt_stem_text(fs)
                map[source_id] = text if text && !text.empty?
              end
            end
            map
          end

          # Cleans raw text of unrendered AsciiDoc inline syntax that
          # the presentation XML didn't convert to proper elements.
          #   "link:mailto:biml@oiml.org" → "biml@oiml.org"
          #   "link:https://example.org"  → "https://example.org"
          def clean_text(text)
            text.to_s
                .gsub(/link:mailto:([^\s\[]+)/, '\1')
                .gsub(/link:([^\s\[]+)/, '\1')
          end

          def collect_fmt_stem_texts(paragraph)
            fmt_stems = paragraph.fmt_stem
            return [] unless fmt_stems.is_a?(Array)

            fmt_stems.map { |fs| fmt_stem_text(fs) }
          end

          def fmt_stem_text(fmt_stem_node)
            text = ::Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor.text_of(fmt_stem_node)
            text.empty? ? "" : " #{text.strip} "
          end

          # Returns true if a FmtStemElement sibling follows the given
          # semantic stem node in the same parent. We can't walk siblings
          # without the parent, so we approximate: assume fmt-stem always
          # accompanies a semantic stem in presentation XML.
          def fmt_stem_follows?(_stem_node)
            # In presentation XML, semantic stems always have a sibling
            # fmt-stem with the rendered form. Returning true means we
            # always defer to the fmt-stem.
            true
          end

          # Returns true if the given node is a SpanElement with a
          # class_attr marking it as pure presentation chrome (delimiters,
          # autonum wrappers). Such spans contain no real content.
          def presentation_span?(node)
            return false unless node.is_a?(Metanorma::Document::Components::Inline::SpanElement)

            cls = node.class_attr
            cls.is_a?(String) && PRESENTATION_SPAN_CLASSES.any? { |c| cls.include?(c) }
          end

          # Convert asciimath notation to readable text matching how
          # Metanorma HTML renders MathML. Subscripts render with a space
          # before the subscript text (matching MN HTML text extraction).
          def asciimath_to_text(ascii)
            text = ascii.to_s
            # Subscript: X_{"Y"} → X Y (space before subscript)
            text = text.gsub(/(\w)_\{"([^"]+)"\}/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_\{([^}]+)\}/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_\(([^)]+)\)/) { "#{$1} #{$2}" }
            text = text.gsub(/(\w)_(\w)/) { "#{$1} #{$2}" }
            # Superscript: X^{"Y"} → XY (no space, matches MN)
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

          def eref_text(node)
            citeas = node.citeas rescue nil
            return citeas.to_s if citeas && !citeas.to_s.empty?

            text_of(node)
          end

          def extract_stem_value(val)
            return nil if val.nil?
            return val.to_s.strip if val.is_a?(String)

            if val.is_a?(Array)
              strs = val.map { |v| extract_stem_value(v).to_s }
              return strs.join.strip
            end

            class_name = val.class.name&.split("::")&.last

            # AsciimathElement exposes text via the public .text accessor.
            if class_name == "AsciimathElement"
              txt = val.text
              return extract_stem_value(txt) if txt
            end

            # Generic object with .text or .content
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

            # For mailto: links, use the email address as visible text
            visible_text = if href.to_s.start_with?("mailto:")
                             href.sub(/\Amailto:/, "")
                           else
                             link_text(node)
                           end

            ::Sts::IsoSts::ExtLink.new(
              ext_link_type: "uri",
              xlink_href: href,
              content: visible_text
            )
          end

          # LinkElement stores its visible text in the `content` collection
          # (mixed_content), not via a `text` method.
          def link_text(node)
            if node.respond_to?(:content)
              c = node.content
              c = Array(c) unless c.is_a?(Array)
              joined = c.map(&:to_s).join.strip
              return joined unless joined.empty?
            end
            text_of(node)
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

            xref_type = begin
              node.type
            rescue StandardError
              nil
            end
            visible_text = xref_visible_text(node, rid)
            ::Sts::TbxIsoTml::Xref.new(
              rid: rid,
              ref_type: ref_type_for(xref_type),
              value: visible_text
            )
          end

          # Renders a human-friendly visible label for an empty xref.
          # Metanorma renders <xref target="sec-3.6"/> as "3.6", so we
          # strip the type prefix from the rid to approximate this.
          # For bibitem anchors (e.g. OIML_R_76_2006), wrap in brackets.
          def xref_visible_text(node, rid)
            explicit = text_of(node)
            return explicit unless explicit.empty?

            case rid
            when /\Asec-(.+)\z/        then Regexp.last_match(1)
            when /\Afig-(.+)\z/        then "Figure #{Regexp.last_match(1)}"
            when /\Atable-(.+)\z/      then "Table #{Regexp.last_match(1)}"
            when /\Afn-(.+)\z/         then Regexp.last_match(1)
            when /\A[A-Z][A-Z0-9_]*\z/ then "[#{rid}]"
            else rid
            end
          end

          def build_fn(node)
            id = begin
              node.id
            rescue StandardError
              nil
            end || begin
              node.reference
            rescue StandardError
              nil
            end
            return nil unless id

            sts_id = context.footnote_collector.register(id)
            fn_text = Array(node.p).map { |p| text_of(p) }.reject(&:empty?).join(" ")
            ::Sts::TbxIsoTml::Fn.new(id: sts_id, value: fn_text)
          end

          def build_stem(node)
            text = stem_text(node)
            return nil if text.nil? || text.empty?
            ::Sts::IsoSts::InlineFormula.new(content: [text])
          end

          def ref_type_for(mn_type)
            case mn_type.to_s
            when "clause", "section" then "sec"
            when "table" then "table"
            when "figure", "fig" then "fig"
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
