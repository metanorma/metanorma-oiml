# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class NoteTransformer < Base
          def transform(source_note)
            class_name = source_note.class.name&.split("::")&.last

            case class_name
            when "NoteBlock"
              ::Sts::IsoSts::NonNormativeNote.new(paragraph: build_paragraphs(source_note))
            when "ExampleBlock"
              ::Sts::IsoSts::NonNormativeExample.new(paragraph: build_paragraphs(source_note))
            when "AdmonitionBlock"
              ::Sts::IsoSts::NonNormativeNote.new(paragraph: build_paragraphs(source_note))
            when "QuoteBlock"
              ::Sts::NisoSts::DispQuote.new(p: build_paragraphs(source_note))
            else
              ::Sts::IsoSts::NonNormativeNote.new(paragraph: build_paragraphs(source_note))
            end
          end

          def transform_preformat(source_block)
            content = extract_text(source_block)
            ::Sts::IsoSts::Preformat.new(content: content.any? ? content : [""])
          end

          private

          def build_paragraphs(source_note)
            result = []
            if source_note.respond_to?(:content) && source_note.content
              Array(source_note.content).each do |p|
                if p.is_a?(String)
                  result << ::Sts::IsoSts::Paragraph.new(content: [p])
                else
                  result << paragraph_transformer.transform(p)
                end
              end
            end
            if source_note.respond_to?(:paragraphs)
              Array(source_note.paragraphs).each { |p| result << paragraph_transformer.transform(p) }
            end
            result
          end

          def extract_text(source_block)
            %i[text content name].each do |attr|
              next unless source_block.respond_to?(attr)
              val = source_block.public_send(attr)
              next if val.nil?
              strs = Array(val).map(&:to_s).reject(&:empty?)
              return strs if strs.any?
            end
            []
          end
        end
      end
    end
  end
end
