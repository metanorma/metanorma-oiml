# frozen_string_literal: true

# Delegates to the shared engine (metanorma-document 0.5.15, Metanorma::Document::Sts)
# per metanorma-iso#1760 / metanorma-document#165.

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        # OIML additions on top of the shared renderer:
        # - mirrored STS numbering schemes (arabic, alpha, roman) render as <ol>;
        # - a parsed non-mixed container with no element_order renders every
        #   repeated child, not only the first of each collection.
        class Ruby < Metanorma::Document::Sts::HtmlRenderer::Ruby
          ORDERED_LIST_TYPES = %w[order arabic alpha-lower alpha-upper
                                  roman-lower roman-upper].freeze

          private

          def list(node)
            tag = ORDERED_LIST_TYPES.include?(node.list_type) ? "ol" : "ul"
            css = labeled_list?(node) ? "mn-labeled-list" : nil
            render_element(tag, render_children(node), css: css)
          end

          def declared_element_order(node, mapping)
            return [] if node.nil?

            mapping.flat_map do |name, attr|
              value = node.public_send(attr)
              count = value.is_a?(Array) ? [value.size, 1].max : 1
              Array.new(count) do
                Metanorma::Document::Sts::HtmlRenderer::Ruby::DeclaredEntry
                  .new(:element, name, nil)
              end
            end
          end
        end
      end
    end
  end
end
