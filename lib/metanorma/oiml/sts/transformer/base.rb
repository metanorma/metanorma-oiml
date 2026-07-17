# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Shared base for every transformer. Provides access to the
        # conversion {Context} and factory methods for child transformers.
        # Transformers RETURN model instances — they do not emit into a
        # builder.
        class Base
          attr_reader :context

          def initialize(context)
            @context = context
          end

          private

          def source
            context.source
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

          def term_transformer
            TermTransformer.new(context)
          end
        end
      end
    end
  end
end
