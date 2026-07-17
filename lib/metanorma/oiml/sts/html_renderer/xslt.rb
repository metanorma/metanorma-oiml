# frozen_string: true

require "nokogiri"

module Metanorma
  module Oiml
    module Sts
      module HtmlRenderer
        # XSLT-based renderer: applies the OIML STS XSLT 1.0 stylesheet
        # (compatible with Nokogiri) to produce semantic HTML.
        class Xslt
          STYLESHEET_PATH = File.expand_path(
            "../../../../../vendor/xslt/oiml-sts2html.xsl", __dir__
          )

          def render(sts_xml)
            xslt_transform(sts_xml)
          end

          def xslt_transform(sts_xml)
            stylesheet = Nokogiri::XSLT(File.read(STYLESHEET_PATH))
            doc = Nokogiri::XML(sts_xml)
            stylesheet.transform(doc).to_s
          end

          def stylesheet_text
            File.read(STYLESHEET_PATH)
          end
        end
      end
    end
  end
end
