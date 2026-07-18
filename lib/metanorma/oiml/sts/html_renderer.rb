# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      # HTML rendering for OIML STS XML.
      module HtmlRenderer
        autoload :Xslt, "#{__dir__}/html_renderer/xslt"
        autoload :Ruby, "#{__dir__}/html_renderer/ruby"

        DEFAULT_RENDERER = :ruby

        module_function

        def render(sts_xml, renderer: DEFAULT_RENDERER)
          case renderer
          when :xslt then Xslt.new.render(sts_xml)
          when :ruby then Ruby.new.render(sts_xml)
          else raise ArgumentError, "unknown renderer: #{renderer.inspect}"
          end
        end
      end
    end
  end
end
