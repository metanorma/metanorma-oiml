# frozen_string_literal: true

require "pathname"
require "set"

REPO_ROOT = Pathname.new(File.expand_path("..", __dir__))
FIXTURES_ROOT = REPO_ROOT.join("spec", "fixtures").freeze

require "metanorma/oiml/sts"
require "support/content_matcher"
require "support/xsd_validator"
require "support/html_fingerprint"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.disable_monkey_patching!
  config.warnings = true
  config.default_formatter = "doc" if config.files_to_run.one?
  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
