# frozen_string_literal: true

require_relative "lib/metanorma/oiml/version"

Gem::Specification.new do |spec|
  spec.name = "metanorma-oiml"
  spec.version = Metanorma::Oiml::VERSION
  spec.authors = ["Ribose Inc."]
  spec.email = ["open.source@ribose.com"]

  spec.summary = "Metanorma for OIML"
  spec.description = spec.summary
  spec.homepage = "https://github.com/metanorma/metanorma-oiml"
  spec.license       = "BSD-2-Clause"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    Dir["lib/**/*", "exe/*", "schematron/**/*", "vendor/**/*",
        "README*", "LICENSE*"]
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "metanorma-document", ">= 0.2.5"
  spec.add_dependency "sts", ">= 0.1"
  spec.add_dependency "lutaml-model", "~> 0.8.0"
  spec.add_dependency "thor", ">= 1.2"
  spec.add_dependency "plurimath"
  spec.add_dependency "nokogiri", ">= 1.13"
end
