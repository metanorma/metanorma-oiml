# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class FigureTransformer < Metanorma::Document::Sts::Transformer::FigureTransformer
          # OIML keeps the original asset path for HTML rendering.
          def self.image_href(img)
            %i[source filename].each do |attr|
              href = img.public_send(attr) if img.class.attributes.key?(attr)
              return href if href && !href.empty?
            end
            nil
          end
        end
      end
    end
  end
end
