# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Walks typed model objects that wrap presentation-format XML
        # (fmt-preferred, fmt-stem, fmt-definition) and extracts the full
        # rendered text including math content.
        #
        # The typed model loses `<stem>` elements in some contexts
        # (e.g. `TermNameElement` has no `stem` attribute), so we must
        # walk the rendered trees which preserve them.
        #
        # All dispatch is by class (is_a?) — never respond_to?.
        class RenderedTextExtractor
          # Typed model classes that expose a mixed_content collection
          # we can walk in document order.
          WALKABLE_TYPES = [
            Metanorma::Document::Components::Paragraphs::ParagraphBlock,
            Metanorma::Document::Components::Inline::SemxElement,
            Metanorma::Document::Components::Inline::StrongRawElement,
            Metanorma::Document::Components::Inline::EmRawElement,
            Metanorma::Document::Components::Inline::SpanElement,
            Metanorma::Document::Components::Inline::FmtPreferredElement,
            Metanorma::Document::Components::Inline::FmtXrefLabelElement,
            Metanorma::Document::Components::Inline::FmtConceptElement,
            Metanorma::Document::Components::Inline::FmtStemElement,
            Metanorma::Document::Components::Inline::MathElement,
            Metanorma::Document::Components::Inline::ConceptElement,
            Metanorma::StandardDocument::Sections::ContentSection,
          ].freeze

          # Typed inline classes whose visible text we want to extract
          # directly (recurse via each_mixed_content).
          RECURSIVE_INLINE_TYPES = [
            Metanorma::Document::Components::Inline::StrongRawElement,
            Metanorma::Document::Components::Inline::EmRawElement,
            Metanorma::Document::Components::Inline::SpanElement,
          ].freeze

          # Stem types — extract via asciimath, pad with surrounding spaces.
          STEM_TYPES = [
            Metanorma::Document::Components::Inline::StemInlineElement,
          ].freeze

          def self.text_of(node)
            return "" if node.nil?
            return node if node.is_a?(String)

            # FmtStemElement: walk its semx collection directly (it
            # doesn't expose each_mixed_content at the top level).
            if node.is_a?(Metanorma::Document::Components::Inline::FmtStemElement)
              extractor = new
              # Walk ONLY MathElement children of the fmt-stem's semx.
              # The fmt-stem's MathElement has the rendered form (decimal
              # commas, thousands separators). The AsciimathElement sibling
              # has the semantic form (periods) — skip it to avoid dup.
              Array(node.semx).each do |semx|
                Array(semx.math).each do |math_el|
                  mathml = math_el.content.to_s
                  text = ::Metanorma::Oiml::Sts::MathmlBuilder.mathml_to_plain_text(mathml)
                  extractor.append_text(text) unless text.empty?
                end
              end
              return extractor.to_text
            end

            # Stem types: extract via asciimath/MathML directly.
            return stem_text_for(node).strip if stem_type?(node)
            return "" unless walkable?(node)

            walker = new
            walker.collect(node)
            walker.to_text
          end

          # Public class methods (kept off the private API to avoid send).
          def self.stem_type?(node)
            STEM_TYPES.any? { |t| node.is_a?(t) }
          end

          # Returns the rendered text of a single stem element (no
          # surrounding whitespace). Public class method so callers
          # don't need to instantiate.
          def self.stem_text_for(node)
            extractor = new
            raw = extractor.extract_stem(node)
            raw.nil? || raw.empty? ? "" : raw.strip
          end

          # Returns the rendered text of a single stem element WITH
          # surrounding whitespace, matching MN HTML's browser rendering
          # of <span class="stem"><math>…</math></span> which pads the
          # math content with spaces.
          def self.stem_text_padded(node)
            extractor = new
            raw = extractor.extract_stem(node)
            raw.nil? || raw.empty? ? "" : raw
          end

          def self.walkable?(node)
            WALKABLE_TYPES.any? { |t| node.is_a?(t) } ||
              node.class.method_defined?(:each_mixed_content)
          end
          public_class_method :walkable?

          # Public instance method — used by the class method above and
          # by #collect_node. Returns padded text (with surrounding spaces).
          def extract_stem(node)
            stem_text(node)
          end

          def initialize
            @parts = []
            @seen = {}
            @seen_stems = {}
          end

          def to_text
            @parts.join.strip
          end

          # Public method to append pre-extracted text. Used by class
          # methods that do targeted extraction (e.g. FmtStemElement
          # MathElement-only walk).
          def append_text(text)
            @parts << text
          end

          # Public wrapper for collect_node so class methods can call it
          # without bypassing encapsulation via send.
          def collect_node_public(child)
            collect_node(child)
          end

          def collect(node)
            return if node.nil? || @seen.key?(node.object_id)
            @seen[node.object_id] = true

            if node.is_a?(String)
              @parts << node
              return
            end
            return unless self.class.walkable?(node)

            node.each_mixed_content { |child| collect_node(child) }
          end

          private

          def collect_node(child)
            if child.is_a?(String)
              @parts << child
              return
            end

            case child
            when *STEM_TYPES
              @parts << extract_stem(child)
            when Metanorma::Document::Components::Inline::AsciimathElement
              @parts << plain_asciimath(array_or_string_to_s(child.text))
            when Metanorma::Document::Components::Inline::MathElement
              # MathElement.content holds the raw MathML XML string.
              # Walk it via MathmlBuilder to preserve decimal commas,
              # thousands separators, and Unicode operators.
              mathml = child.content.to_s
              text = ::Metanorma::Oiml::Sts::MathmlBuilder.mathml_to_plain_text(mathml)
              @parts << text
            when Metanorma::Document::Components::Inline::FmtStemElement
              # FmtStemElement holds a SemxElement collection (not
              # mixed_content). Walk semx children explicitly.
              Array(child.semx).each { |semx| collect_node(semx) }
            when Metanorma::Document::Components::Inline::XrefElement
              @parts << xref_text(child)
            when Metanorma::Document::Components::Inline::SemxElement
              collect(child)
              collect_semx_inlines(child)
            when *RECURSIVE_INLINE_TYPES
              collect(child)
            else
              collect(child)
            end
          end

          # SemxElement wraps semantic content; its nested stem/strong/em
          # children surface via dedicated *_child attributes.
          def collect_semx_inlines(semx)
            SEMX_CHILD_ATTRS.each do |attr|
              val = semx.public_send(attr) if semx.class.method_defined?(attr)
              next if val.nil?
              Array(val).each { |v| collect_node(v) }
            end
          end

          SEMX_CHILD_ATTRS = %i[
            stem_child strong em sup sub tt underline strike
            preferred_child name_child title_child
            verbal_definition_child definition_child
            concept_child fn_child link_child
          ].freeze

          def stem_text(stem_node)
            # Prefer MathML extraction: it preserves decimal commas,
            # thousands separators, and original Unicode operators.
            mathml = stem_node_mathml(stem_node)
            text = mathml && !mathml.empty? ?
              ::Metanorma::Oiml::Sts::MathmlBuilder.mathml_to_plain_text(mathml) :
              nil
            if text.nil? || text.empty?
              ascii = stem_node_asciimath(stem_node)
              text = ascii && !ascii.empty? ? plain_asciimath(ascii) : ""
            end
            return "" if text.nil? || text.empty?

            # Deduplicate: the typed model exposes each stem via multiple
            # paths (semantic + rendered), so the same content may be
            # visited twice. Skip subsequent visits.
            key = text.to_s
            return "" if @seen_stems.key?(key)
            @seen_stems[key] = true

            # MN HTML renders `<stem>` inside a <span class="stem"> which
            # browsers pad with whitespace. Emit the math text with
            # surrounding spaces to match.
            " #{text} "
          end

          def stem_node_mathml(stem_node)
            return nil unless stem_node.class.method_defined?(:math)
            math_arr = stem_node.math
            math_val = Array(math_arr).first
            return nil unless math_val
            # Mml::V3::Math serializes to the MathML XML we want to
            # extract text from.
            math_val.to_xml
          rescue StandardError
            nil
          end

          def stem_node_asciimath(stem_node)
            %i[asciimath text].each do |attr|
              next unless stem_node.class.method_defined?(attr)
              val = stem_node.public_send(attr)
              next if val.nil?
              s = array_or_string_to_s(val)
              return s if s && !s.empty?
            end
            nil
          end

          def array_or_string_to_s(val)
            return val if val.is_a?(String)
            return "" unless val.is_a?(Array)
            val.map { |v| v.is_a?(String) ? v : object_text(v) }
               .reject(&:empty?)
               .join.strip
          end

          def object_text(obj)
            return obj.to_s if obj.is_a?(String)
            return "" unless obj
            return obj.text.to_s if obj.class.method_defined?(:text)
            return obj.value.to_s if obj.class.method_defined?(:value)
            return obj.content.to_s if obj.class.method_defined?(:content)
            obj.to_s
          end

          def plain_asciimath(ascii)
            ::Metanorma::Oiml::Sts::MathmlBuilder.asciimath_to_plain_text(ascii.to_s)
          end

          # XrefElement visible text: use embedded text if present,
          # otherwise fall back to the target rid suffix.
          def xref_text(xref)
            txt = array_or_string_to_s(xref.text)
            return txt unless txt.nil? || txt.empty?

            rid = xref.target
            return "" unless rid.is_a?(String) && !rid.empty?

            case rid
            when /\Asec-(.+)\z/, /\Afig-(.+)\z/, /\Atable-(.+)\z/, /\Afn-(.+)\z/
              Regexp.last_match(1)
            else
              rid
            end
          end
        end
      end
    end
  end
end
