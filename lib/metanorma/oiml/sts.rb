# frozen_string_literal: true

require "metanorma/document"

# OIML NISO STS toolkit.
#
# Public API:
#   Metanorma::Oiml::Sts.convert(xml)        # -> sts xml string
#   Metanorma::Oiml::Sts.validate(xml)       # -> ValidationReport
#   Metanorma::Oiml::Sts::Cli.start(argv)    # Thor CLI entry
#
# The Transformer namespace mirrors `Metanorma::Iso::Sts::Transformer` from
# the `metanorma-iso` gem.
module Metanorma
  module Oiml
    module Sts
      autoload :VERSION, "metanorma/oiml/sts/version"
      autoload :Transformer, "metanorma/oiml/sts/transformer"
      autoload :Validator, "metanorma/oiml/sts/validator"
      autoload :ValidationReport, "metanorma/oiml/sts/validation_report"
      autoload :Cli, "metanorma/oiml/sts/cli"

      # Convert a Metanorma OIML presentation XML string (or anything
      # `SourceDocument.parse` accepts) into an OIML NISO STS XML string.
      #
      # @param input [String, Pathname, #read] the source XML.
      # @return [String] OIML NISO STS XML.
      def self.convert(input)
        source = Transformer::SourceDocument.parse(input)
        context = Transformer::Context.new(source)
        Transformer::DocumentTransformer.new(context).transform_to_xml(source)
      end

      # Validate an OIML NISO STS XML string against the OIML X 999:2026
      # constraints (Schematron + lutaml-model rules).
      #
      # @param xml [String, Pathname, #read] the STS XML.
      # @return [ValidationReport]
      def self.validate(xml)
        Validator.new.validate(xml)
      end
    end
  end
end
