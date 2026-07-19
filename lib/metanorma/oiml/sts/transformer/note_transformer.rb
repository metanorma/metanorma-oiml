# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class NoteTransformer < Base
          def transform(source_note)
            paragraphs = extract_paragraphs(source_note)
            return nil if paragraphs.empty?

            if example?(source_note)
              ModelBuilder.non_normative_example(paragraph: paragraphs)
            else
              ModelBuilder.non_normative_note(paragraph: paragraphs)
            end
          end

          def transform_preformat(source_code)
            text = source_code.content if source_code.class.method_defined?(:content)
            text = source_code.text if text.nil? && source_code.class.method_defined?(:text)
            ::Sts::IsoSts::Preformat.new(content: Array(text))
          end

          private

          def extract_paragraphs(source_note)
            if source_note.class.method_defined?(:paragraphs)
              ps = Array(source_note.paragraphs)
            elsif source_note.class.method_defined?(:content)
              ps = Array(source_note.content).select { |p| p.is_a?(Metanorma::Document::Components::Paragraphs::ParagraphBlock) }
            else
              ps = []
            end
            ps.map { |p| paragraph_transformer.transform(p) }
          end

          def note_type(source_note)
            source_note.class.name.split("::").last
          end

          # Returns :example for ExampleBlock, :note for everything else.
          # Used to choose between NonNormativeExample and NonNormativeNote.
          def example?(source_note)
            note_type(source_note) == "ExampleBlock"
          end
        end
      end
    end
  end
end
