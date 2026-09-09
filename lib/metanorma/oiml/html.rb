# frozen_string_literal: true

require "metanorma/iso/html"

module Metanorma
  module Oiml
    # HTML format slice for the flavor: the renderer, registered with
    # the harness from oiml/document.rb. Renders iso-style; the OIML
    # root uses the ISO section classes the ISO renderer registers.
    module Html
      autoload :Renderer, "#{__dir__}/html/renderer"
    end
  end
end
