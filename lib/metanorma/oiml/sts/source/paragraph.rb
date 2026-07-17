# frozen_string_literal: true

module Metanorma::Oiml::Sts::Source
  # Wraps ParagraphBlock. Exposes inline content via each_inline,
  # which yields typed inline elements in document order.
  class Paragraph < Base
    # Yield each inline child in document order.
    # Strings are yielded as-is; typed elements are yielded raw
    # (the transformer decides how to handle each class).
    def each_inline
      return enum_for(:each_inline) unless block_given?

      typed.each_mixed_content do |node|
        yield node
      end
    end

    # Plain text content (concatenation of all text segments).
    def text
      segments = []
      typed.each_mixed_content do |node|
        segments << (node.is_a?(String) ? node : InlineExtractor.text_from(node))
      end
      segments.join.strip
    end

    # Text strings only (no inline elements).
    def text_strings
      Array(typed.text)
    end

    # Bold elements.
    def bolds
      Array(typed.strong)
    end

    # Italic elements.
    def italics
      Array(typed.em)
    end

    # Subscript elements.
    def subs
      Array(typed.sub)
    end

    # Superscript elements.
    def sups
      Array(typed.sup)
    end

    # Monospace elements.
    def monospaces
      Array(typed.tt)
    end

    # Underline elements.
    def underlines
      Array(typed.underline)
    end

    # Strike elements.
    def strikes
      Array(typed.strike)
    end

    # Link elements.
    def links
      Array(typed.link)
    end

    # Xref elements.
    def xrefs
      Array(typed.xref)
    end

    # Eref elements.
    def erefs
      Array(typed.eref)
    end

    # Footnote elements.
    def footnotes
      Array(typed.fn)
    end

    # Stem elements.
    def stems
      Array(typed.stem)
    end

    # Note elements (inline notes inside paragraphs).
    def notes
      Array(typed.note)
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Paragraphs::ParagraphBlock,
  Metanorma::Oiml::Sts::Source::Paragraph
)
