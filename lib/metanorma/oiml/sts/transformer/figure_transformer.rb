# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FigureTransformer < Base
          def transform(source_figure)
            attrs = {}
            attrs[:id] = source_figure.id if source_figure.respond_to?(:id) && source_figure.id

            label = extract_label(source_figure)
            attrs[:label] = ::Sts::IsoSts::Label.new(content: [label]) if label

            caption_text = extract_caption(source_figure)
            attrs[:caption] = ::Sts::IsoSts::Caption.new(
              title: ::Sts::IsoSts::Title.new(content: [caption_text])
            ) if caption_text

            graphic = build_graphic(source_figure)
            attrs[:graphic] = [graphic] if graphic

            ::Sts::IsoSts::Fig.new(attrs)
          end

          private

          def extract_label(source_figure)
            return nil unless source_figure.respond_to?(:autonum)
            num = source_figure.autonum
            num.to_s.strip unless num.to_s.strip.empty?
          end

          def extract_caption(source_figure)
            name = source_figure.respond_to?(:name) ? source_figure.name : nil
            return nil unless name

            text = (name.text rescue nil)
            text = Array(text).first if text.is_a?(Array)
            text.to_s.strip
          end

          def build_graphic(source_figure)
            image = source_figure.respond_to?(:image) ? source_figure.image : nil
            return nil unless image

            href = (image.source rescue nil) || (source_figure.source rescue nil)
            return nil unless href

            attrs = { xlink_href: href }
            attrs[:mimetype] = image.mimetype if image.respond_to?(:mimetype) && image.mimetype

            ::Sts::IsoSts::Graphic.new(attrs)
          end
        end
      end
    end
  end
end
