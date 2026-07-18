# frozen_string_literal: true

require "metanorma/document"
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
