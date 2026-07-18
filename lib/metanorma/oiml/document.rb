# frozen_string_literal: true

require "metanorma/document"
# OIML is an ISO-family flavor: the ISO document register must exist for
# the oiml_document register fallback to resolve during parsing.
require "metanorma/iso_document"

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
      autoload :Root, "metanorma/oiml/document/root"
    end
  end
end

Metanorma::Registers::Setup.setup_oiml_register
