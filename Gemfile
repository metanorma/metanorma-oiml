# frozen_string_literal: true

source "https://rubygems.org"

gemspec
gem "metanorma-mirror", "~> 1.0"
gem "mml", ">= 2.0"

# TEMPORARY audit chain — flip each to main on merge, version on release
gem "metanorma-document", github: "metanorma/metanorma-document", branch: "main"
gem "metanorma-standoc", github: "metanorma/metanorma-standoc", branch: "feat/term-grammar-coverage"
gem "metanorma-iso", github: "metanorma/metanorma-iso", branch: "feat/model-validation-migration"
gem "metanorma-core", github: "metanorma/metanorma-core", branch: "feat/flavor-table"
gem "isodoc", github: "metanorma/isodoc", branch: "main"

group :development do
  gem "pry"
  gem "rake"
  gem "rspec"
  gem "rubocop"
end
