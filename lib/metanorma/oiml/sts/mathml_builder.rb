# frozen_string_literal: true

require "plurimath"

module Metanorma::Oiml::Sts
  # Converts asciimath strings to MathML fragments using Plurimath.
  # Returns the inner MathML (without the wrapping <math> element) so
  # it can be embedded inside <inline-formula> or <disp-formula>.
  module MathmlBuilder
    module_function

    def mathml_for(asciimath_text)
      return nil if asciimath_text.nil? || asciimath_text.strip.empty?

      formula = Plurimath::Math.parse(asciimath_text, :asciimath)
      full_mathml = formula.to_mathml.to_s
      strip_math_wrapper(full_mathml)
    rescue Parslet::ParseFailed, StandardError
      nil
    end

    def strip_math_wrapper(mathml)
      mathml
        .sub(%r{\A\s*<math[^>]*>\s*}m, "")
        .sub(%r{\s*</math>\s*\z}m, "")
        .strip
    end

    def asciimath_to_plain_text(asciimath)
      return "" if asciimath.nil?

      text = asciimath.to_s
      text = apply_subscript_rules(text)
      text = apply_superscript_rules(text)
      text = apply_symbol_rules(text)
      text = text.gsub(/"/, "").gsub(/\s+/, " ").strip
      text
    end

    def apply_subscript_rules(text)
      text.gsub(/(\w)_\{"([^"]+)"\}/, '\1 \2')
          .gsub(/(\w)_\{([^}]+)\}/, '\1 \2')
          .gsub(/(\w)_\(([^)]+)\)/, '\1 \2')
          .gsub(/(\w)_(\w)/, '\1 \2')
    end

    def apply_superscript_rules(text)
      text.gsub(/(\w)\^\{"([^"]+)"\}/, '\1\2')
          .gsub(/(\w)\^\{([^}]+)\}/, '\1\2')
          .gsub(/(\w)\^\(([^)]+)\)/, '\1\2')
          .gsub(/(\w)\^(\w)/, '\1\2')
    end

    def apply_symbol_rules(text)
      text.gsub(/\bcdot\b/, "·")
          .gsub(/\btimes\b/, "×")
          .gsub(/\ble\b/, "≤")
          .gsub(/\bge\b/, "≥")
          .gsub(/\bne\b/, "≠")
          .gsub(/\bapprox\b/, "≈")
          # Two-char ASCII operators → Unicode. Order matters: match
          # longer sequences (<=, >=, !=, =>) before single chars (-, =).
          .gsub(/<=/, "≤")
          .gsub(/>=/, "≥")
          .gsub(/!=/, "≠")
          .gsub(/=>/, "⇒")
          .gsub(/<->/, "↔")
          .gsub(/->/, "→")
          .gsub(/<-/, "←")
          .gsub(/\bsqrt\b/, "√")
          .gsub(/\binfty\b/, "∞")
          .gsub(/\bsum\b/, "∑")
          .gsub(/\bprod\b/, "∏")
          .gsub(/\bint\b/, "∫")
    end

    # Walks a MathML XML string and extracts visible text, preserving
    # the original number formatting (decimal commas, thousands
    # separators) that the semantic asciimath form loses.
    #
    # Operator conversions follow the asciimath rules above.
    def mathml_to_plain_text(mathml_xml)
      return "" if mathml_xml.nil? || mathml_xml.to_s.strip.empty?

      text = extract_mathml_text(mathml_xml.to_s)
      text = text.gsub(/\s+/, " ").strip
      apply_symbol_rules(text)
    end

    # Extracts text content from <mi>, <mn>, <mo>, <mtext>, and <ms> elements
    # within MathML. Joins adjacent elements with spaces. Preserves the
    # original formatting (e.g. <mn>0,1</mn> → "0,1" with decimal comma).
    def extract_mathml_text(xml)
      # Strip XML comments and processing instructions
      cleaned = xml.gsub(/<!--.*?-->/m, "").gsub(/<\?.*?\?>/m, "")
      # Extract text content from math elements, joining with spaces
      # between siblings. Removes element tags but keeps their text.
      parts = []
      scanner = StringScanner.new(cleaned)
      until scanner.eos?
        if scanner.scan(/<\/?[a-zA-Z:][^>]*>/m)
          # Tag — insert a separator between siblings at element boundaries
          parts << " " if scanner.matched =~ /\A<\/|\A<(?!mstyle|mrow|mfrac|mstyle|msub|msup|msubsup|munder|mover)\b/
        else
          text = scanner.scan(/[^<]+/)
          break unless text
          parts << text
        end
      end
      parts.join
    rescue StandardError
      ""
    end
  end
end
