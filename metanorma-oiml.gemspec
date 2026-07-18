# frozen_string_literal: true

require_relative "lib/metanorma/oiml/sts/version"

Gem::Specification.new do |spec|
  spec.name = "metanorma-oiml"
  spec.version = Metanorma::Oiml::Sts::VERSION
  spec.authors = ["OIML"]
  spec.email = ["info@oiml.org"]

  spec.summary = "OIML NISO STS toolkit: Metanorma presentation XML → OIML STS XML " \
                 "transformer, validator, and Schematron rules per OIML X 999:2026."
  spec.description = spec.summary
  spec.homepage = "https://github.com/metanorma/metanorma-oiml"
  spec.license = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "exe/*", "schematron/**/*", "data/**/*", "README*",
        "LICENSE*"]
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "metanorma-document", ">= 0.2.5"
  spec.add_dependency "lutaml-model", ">= 0.7"
  spec.add_dependency "nokogiri", ">= 1.16"
  spec.add_dependency "thor", ">= 1.2"
end
