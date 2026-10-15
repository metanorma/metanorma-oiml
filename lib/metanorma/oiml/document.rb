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

# The flavor-table entry for :oiml is owned by the oiml taste
# (metanorma-taste, base-flavor: iso). Registering a bare entry here as
# well made Core::Flavors.find(:oiml) resolve to it once this gem loads
# (the table walks reverse order), which broke the taste's
# base-flavor resolution and fatal-aborted compiles of the taste.
