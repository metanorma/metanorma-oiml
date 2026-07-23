# frozen_string_literal: true

require "metanorma/document"

module Metanorma
  module Oiml
    # HTML renderer and document flavor registration for the OIML
    # flavor of metanorma-document. The Html namespace's child
    # constants (Renderer, Theme) are autoloaded from the parent
    # namespace's file (this one) per the project's no-require_relative
    # rule.
    module Html
      autoload :Renderer, "#{__dir__}/html/renderer"
    end

    module Document
      autoload :Root, "#{__dir__}/document/root"
    end
  end
end

require "metanorma/oiml/document"
require "metanorma/oiml/html/renderer"

# Registers the OIML document flavor with metanorma-document's HTML
# generator: the model class, the renderer, and the theme assets that
# ship with this gem (data/themes/oiml).
Metanorma::Html::Generator.flavors.register(
  Metanorma::Html::Flavor.new(
    name: :oiml,
    model_class: Metanorma::Oiml::Document::Root,
    renderer_class: Metanorma::Oiml::Html::Renderer,
    pubid_module: :"Pubid::Oiml",
  ),
)

Metanorma::Html::Theme.register_themes_dir(
  File.expand_path("../../../data/themes", __dir__),
)
