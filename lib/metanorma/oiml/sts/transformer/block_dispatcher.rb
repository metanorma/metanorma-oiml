# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Dispatches a Metanorma block element to the right per-element
        # transformer. Adding a new block type = adding one entry to
        # {HANDLERS} (Open/Closed).
        class BlockDispatcher < Base
          HANDLERS = {
            "clause"    => :dispatch_via_section,
            "p"         => :dispatch_via_paragraph,
            "ul"        => :dispatch_via_list,
            "ol"        => :dispatch_via_list,
            "table"     => :dispatch_via_table,
            "figure"    => :dispatch_via_figure,
            "formula"   => :dispatch_via_formula,
            "note"      => :dispatch_via_note,
            "example"   => :dispatch_via_note,
            "quote"     => :dispatch_via_note,
            "bibitem"   => :dispatch_via_reference
          }.freeze

          def dispatch(source_node, builder)
            handler = HANDLERS[source_node.name]
            return unless handler

            send(handler, source_node, builder)
          end

          def handles?(source_node)
            HANDLERS.key?(source_node.name)
          end

          private

          def dispatch_via_section(node, builder);  section_transformer.transform(node, builder);   end
          def dispatch_via_paragraph(node, builder); paragraph_transformer.transform(node, builder); end
          def dispatch_via_list(node, builder);     list_transformer.transform(node, builder);     end
          def dispatch_via_table(node, builder);    table_transformer.transform(node, builder);    end
          def dispatch_via_figure(node, builder);   figure_transformer.transform(node, builder);   end
          def dispatch_via_formula(node, builder);  formula_transformer.transform(node, builder);  end
          def dispatch_via_note(node, builder);     note_transformer.transform(node, builder);     end
          def dispatch_via_reference(node, builder); reference_transformer.transform(node, builder); end
        end
      end
    end
  end
end
