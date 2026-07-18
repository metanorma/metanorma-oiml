# frozen_string_literal: true

require "metanorma/document"

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

  module OimlDocument
    autoload :Root, "metanorma/oiml_document/root"
  end
end

Metanorma::Registers::Setup.setup_oiml_register
