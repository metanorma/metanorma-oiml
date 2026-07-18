# frozen_string_literal: true

require_relative "../../../spec_helper"
require_relative "../../../support/roundtrip_helper"
require_relative "../../../support/shared_roundtrip_examples"
require "metanorma/oiml_document"

RSpec.describe "OIML document XML round-trip" do
  it_behaves_like "xml round-trip", flavor_dir: "oiml/r060",
                                    doc_class: Metanorma::OimlDocument::Root
end
