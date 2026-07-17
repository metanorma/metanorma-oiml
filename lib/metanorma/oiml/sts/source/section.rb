# frozen_string_literal: true

module Metanorma::Oiml::Sts::Source
  # Wraps IsoClauseSection / IsoForewordSection / IsoTermsSection /
  # DefinitionSection / AnnexSection — any section-like typed model.
  class Section < Base
    # Iterate child blocks in document order via each_mixed_content.
    def each_block
      return enum_for(:each_block) unless block_given?

      typed.each_mixed_content do |node|
        next if node.is_a?(String)
        yield node
      end
    end

    # Title text of this section.
    def title_text
      title = typed.title
      return nil if title.nil?

      InlineExtractor.text_from(title)
    end

    # Section number/label (may be empty for unnumbered sections).
    def label
      num = typed.number
      num.to_s.strip unless num.nil? || num.to_s.strip.empty?
    end

    # Sub-clauses of this section.
    def clauses
      Array(typed.clause)
    end

    # Terms (only present on IsoTermsSection).
    def terms
      Array(typed.term)
    end

    # Paragraphs directly in this section.
    def paragraphs
      Array(typed.paragraphs)
    end

    # Tables directly in this section.
    def tables
      Array(typed.tables)
    end

    # Figures directly in this section.
    def figures
      Array(typed.figures)
    end

    # Unordered lists directly in this section.
    def unordered_lists
      Array(typed.unordered_lists)
    end

    # Ordered lists directly in this section.
    def ordered_lists
      Array(typed.ordered_lists)
    end

    # Notes directly in this section.
    def notes
      Array(typed.notes)
    end

    # Examples directly in this section.
    def examples
      Array(typed.examples)
    end

    # Definition lists directly in this section.
    def definition_lists
      Array(typed.definition_lists)
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::IsoDocument::Sections::IsoClauseSection,
  Metanorma::Oiml::Sts::Source::Section
)
