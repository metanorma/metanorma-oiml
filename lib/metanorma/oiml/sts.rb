# frozen_string_literal: true

require "metanorma/document"
require "sts"

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
      autoload :MathmlBuilder, "metanorma/oiml/sts/mathml_builder"
      autoload :HtmlRenderer, "metanorma/oiml/sts/html_renderer"
      autoload :ParityValidator, "metanorma/oiml/sts/parity_validator"
      autoload :Validator, "metanorma/oiml/sts/validator"
      autoload :ValidationReport, "metanorma/oiml/sts/validation_report"
      autoload :Cli, "metanorma/oiml/sts/cli"

      # Convert a Metanorma OIML presentation XML string (or anything
      # `SourceDocument.parse` accepts) into an OIML NISO STS XML string.
      #
      # @param input [String, Pathname, #read] the source XML.
      # @return [String] OIML NISO STS XML.
      def self.convert(input)
        model = convert_to_model(input)
        xml = model.to_xml
        inject_namespaces(xml)
          .then { |x| inject_processing_meta(x) }
          .then { |x| fix_lang_attribute(x) }
      end

      # Convert input to the typed Sts::IsoSts::Standard model.
      # Use this when you need the model directly (e.g. passing to the
      # HTML renderer) to avoid the serialize→deserialize roundtrip
      # that can drop XML entities like &lt; in mixed_content contexts.
      #
      # @param input [String, Pathname, #read] the source XML.
      # @return [Sts::IsoSts::Standard] the typed STS model.
      def self.convert_to_model(input)
        source = Transformer::SourceDocument.parse(input)
        context = Transformer::Context.new(source)
        Transformer::DocumentTransformer.new(context).transform(source)
      end

      def self.inject_namespaces(xml)
        return xml if xml.include?("xmlns:xlink")
        xml.sub("<standard", '<standard xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:mml="http://www.w3.org/1998/Math/MathML"')
      end

      def self.inject_processing_meta(xml)
        return xml if xml.include?("<processing-meta")
        meta = '<processing-meta tagset-family="sts" base-tagset="interchange" table-model="xhtml" mathml="MathML 3.0" terminology-model="tbx"/>'
        # Linear scan for the end of the first <standard ...> opening tag.
        # Avoids the polynomial regex previously flagged by CodeQL.
        open_start = xml.index("<standard")
        return xml unless open_start
        open_end = xml.index(">", open_start)
        return xml unless open_end
        xml.dup.insert(open_end + 1, "\n  #{meta}")
      end

      def self.fix_lang_attribute(xml)
        xml.gsub(/\slang="([a-z-]+)"/, ' xml:lang="\\1"')
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
