# frozen_string_literal: true
module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FigureTransformer < Base
          def transform(source_fig)
            attrs = {}
            attrs[:id] = source_fig.id if source_fig.class.method_defined?(:id) && source_fig.id

            label_text = extract_label(source_fig)
            caption_text = extract_title(source_fig)
            graphic = extract_graphic(source_fig)

            ModelBuilder.fig(id: attrs[:id], label: label_text, caption: ModelBuilder.caption(title: caption_text), graphic: graphic)
          end

          private

          def extract_label(source_fig)
            return nil unless source_fig.class.method_defined?(:fmt_name)
            fmt_name = Array(source_fig.fmt_name).first
            return nil unless fmt_name
            RenderedTextExtractor.text_of(fmt_name)
          end

          def extract_title(source_fig)
            return nil unless source_fig.class.method_defined?(:title) && source_fig.title
            RenderedTextExtractor.text_of(source_fig.title)
          end

          def extract_graphic(source_fig)
            return nil unless source_fig.class.method_defined?(:image)
            images = Array(source_fig.image)
            return nil if images.empty?
            img = images.first
            href = img.src if img.class.method_defined?(:src)
            href ||= img.href if img.class.method_defined?(:href)
            return nil unless href
            ModelBuilder.graphic(xlink_href: href)
          end
        end
      end
    end
  end
end
