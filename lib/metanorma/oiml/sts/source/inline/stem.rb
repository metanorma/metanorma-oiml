# frozen_string_literal: true

require "plurimath"

module Metanorma
  module Oiml
    module Sts
      module Source
        module Inline
          # Wraps a typed-model stem element, exposing its asciimath text,
          # MathML, and plain-text rendering.
          class Stem < Base
            def asciimath
              text = read_asciimath(typed)
              text || ""
            end

            def to_plain_text
              Metanorma::Oiml::Sts::MathmlBuilder.asciimath_to_plain_text(asciimath)
            end

            def to_mathml_fragment
              Metanorma::Oiml::Sts::MathmlBuilder.mathml_for(asciimath)
            end

            def kind
              :stem
            end

            private

            def read_asciimath(stem)
              ascii_attr = typed.asciimath
              return nil if ascii_attr.nil?

              Array(ascii_attr).map do |a|
                case a
                when String then a
                else
                  # AsciimathElement exposes text via the public .text accessor.
                  txt = a.text
                  txt.is_a?(String) ? txt : nil
                end
              end.compact.join
            end
          end
        end
      end
    end
  end
end
