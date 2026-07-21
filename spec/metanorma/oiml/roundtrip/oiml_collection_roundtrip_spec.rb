# frozen_string_literal: true

require_relative "../../../spec_helper"
require_relative "../../../support/roundtrip_helper"
require_relative "../../../support/shared_roundtrip_examples"
require "metanorma/oiml/document"

RSpec.describe "OIML Collection XML round-trip" do
  it_behaves_like "collection round-trip", flavor_dir: "oiml/r060"
end
