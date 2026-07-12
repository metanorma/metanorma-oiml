# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Base class for every transformer.
        class Base
          attr_reader :context

          def initialize(context)
            @context = context
          end

          private

          def source
            context.source
          end

          def sts
            @sts ||= StsXml.new
          end

          def dispatcher
            BlockDispatcher.new(context)
          end

          def inline_transformer
            InlineTransformer.new(context)
          end

          def section_transformer
            SectionTransformer.new(context)
          end

          def paragraph_transformer
            ParagraphTransformer.new(context)
          end

          def list_transformer
            ListTransformer.new(context)
          end

          def table_transformer
            TableTransformer.new(context)
          end

          def figure_transformer
            FigureTransformer.new(context)
          end

          def formula_transformer
            FormulaTransformer.new(context)
          end

          def note_transformer
            NoteTransformer.new(context)
          end

          def reference_transformer
            ReferenceTransformer.new(context)
          end
        end
      end
    end
  end
end
