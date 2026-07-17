# frozen_string_literal: true

require "nokogiri"

module Metanorma
  module Oiml
    module Sts
      module Spec
        # Loads and caches the NISO STS XSD schema for validation in specs.
        module XsdValidator
          XSD_DIR = File.expand_path("../fixtures/schemas", __dir__).freeze
          XSD_ENTRY = File.join(XSD_DIR, "NISO-STS-extended-1-mathml3.xsd").freeze

          # The NISO STS 1.0 XSD validates the base element structure.
          # STS 1.2 added `<processing-meta>` and `@dtd-version="1.2"`, which
          # the 1.0 XSD doesn't know about. These are the expected known
          # deviations when validating a 1.2 document against the 1.0 XSD.
          ACCEPTABLE_1_2_DEVIATIONS = [
            /dtd-version.*does not match the fixed value constraint '1\.0'/,
            /Element 'processing-meta': This element is not expected/,
            /Element 'processing-meta'.*not expected/
          ].freeze

          @schema = nil

          module_function

          # Returns a cached Nokogiri::XML::Schema instance. The XSD uses
          # relative imports so it must be loaded from its own directory.
          def schema
            return @schema if @schema

            Dir.chdir(XSD_DIR) do
              @schema = Nokogiri::XML::Schema(File.read(XSD_ENTRY))
            end
          end

          # Validates an STS XML string against the XSD.
          # Returns an array of Nokogiri::XML::SyntaxError.
          def validate(xml)
            doc = Nokogiri::XML(xml)
            schema.validate(doc).to_a
          end

          # Returns only the errors that are NOT acceptable STS 1.2
          # deviations (i.e. real structural problems).
          def unexpected_errors(xml)
            validate(xml).reject do |error|
              ACCEPTABLE_1_2_DEVIATIONS.any? { |pattern| error.message.match?(pattern) }
            end
          end

          # True if the XML passes XSD validation modulo the known STS 1.2
          # additions.
          def valid?(xml)
            unexpected_errors(xml).empty?
          end
        end
      end
    end
  end
end
