# frozen_string_literal: true

require "metanorma/document"
# OIML is an ISO-family flavor: the ISO document register must exist for
# the oiml_document register fallback to resolve during parsing.
require "metanorma/standoc"
require "metanorma/iso/document"

module Metanorma
  module Registers
    module Setup
      # OIML document register: falls back to the ISO document register.
      # Lives in metanorma-oiml since the OIML document model does.
      def self.setup_oiml_register
        reg = Lutaml::Model::Register.new(:oiml_document,
                                          fallback: [:iso_document])
        Lutaml::Model::GlobalRegister.register(reg)
      end
    end
  end

  module Oiml
    module Document
      autoload :Root, "#{__dir__}/document/root"
    end
  end
end

Metanorma::Registers::Setup.setup_oiml_register

require "metanorma-core"

# OCP adoption: ONE registration in the metanorma-core flavor table
# (metanorma-core#18). Lazy: the table exists only on the flavor-table
# line of metanorma-core; skip silently on resolutions without it.
if defined?(Metanorma::Core::Flavors)
  Metanorma::Core::Flavors.register(Metanorma::Core::Flavor.new(
                                      name: :oiml,
                                      gem: "metanorma-oiml",
                                      model_root: Metanorma::Oiml::Document::Root,
                                      pubid_module: nil,
                                      renderers: { html: lambda do |_document, **_options|
                                        require "metanorma/oiml/html"
                                        Metanorma::Oiml::Html::Renderer
                                      end },
                                    ))
end
