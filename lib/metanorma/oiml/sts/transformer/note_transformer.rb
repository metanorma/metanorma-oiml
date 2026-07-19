# frozen_string_literal: true

require "cgi"

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

          # SourcecodeBlock stores its text in body.content (the bare
          # `content` attribute is nil for parsed documents). The body's
          # content is markup-encoded by the model's roundtrip contract;
          # decoded_content (metanorma-document >= 0.3.1) unwraps it —
          # with a local decode as the fallback for older releases.
          def transform_preformat(source_code)
            text = preformat_text(source_code)
            return nil if text.nil? || text.empty?

            ::Sts::IsoSts::Preformat.new(content: [text])
          end

          def preformat_text(source_code)
            body = source_code.body if source_code.class.method_defined?(:body)
            if body
              return body.decoded_content if body.respond_to?(:decoded_content)
              return CGI.unescapeHTML(Array(body.content).join) if body.class.method_defined?(:content)
            end
            text = source_code.content if source_code.class.method_defined?(:content)
            text = source_code.text if (text.nil? || text.empty?) && source_code.class.method_defined?(:text)
            text
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
