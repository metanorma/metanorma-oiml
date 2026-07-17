# frozen_string: true

module Metanorma::Oiml::Sts::Source
  module Inline
    # Wraps an Xref (XrefElement) inline element.
    class Xref < Base
      def kind
        :xref
      end

      def target
        typed.target
      end

      def refid
        typed.refid
      end

      def xref_type
        typed.type
      end

      def text
        InlineExtractor.text_from(typed)
      end

      # Visible text for rendering. If the xref has no explicit text,
      # derive a human-friendly label from the rid (e.g. sec-3.6 → 3.6).
      def visible_text
        explicit = text
        return explicit unless explicit.nil? || explicit.empty?

        derive_label_from_rid(target || refid)
      end

      private

      def derive_label_from_rid(rid)
        return rid if rid.nil? || rid.empty?

        case rid
        when /\Asec-(.+)\z/        then Regexp.last_match(1)
        when /\Afig-(.+)\z/        then Regexp.last_match(1)
        when /\Atable-(.+)\z/      then Regexp.last_match(1)
        when /\Afn-(.+)\z/         then Regexp.last_match(1)
        when /\A[A-Z][A-Z0-9_]*\z/ then "[#{rid}]"
        else rid
        end
      end
    end
  end
end

Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::Inline::XrefElement,
  Metanorma::Oiml::Sts::Source::Inline::Xref
)
