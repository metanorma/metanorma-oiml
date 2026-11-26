# frozen_string_literal: true

RSpec.describe Metanorma::Oiml::Sts::Transformer::BlockDispatcher do
  # metanorma/metanorma-oiml#44: the mirrored IdGenerator evaluates
  # BlockDispatcher::TYPED_ATTR_DISPATCH at load time
  # (IdGenerator::IdWalk::WALK_ATTRS); a dispatcher that lacks the table
  # breaks the whole suite at load with an uninitialized-constant error.
  # Referencing both constants here reproduces that load path.
  it "defines the typed dispatch table the id walk mirrors" do
    expect(described_class::TYPED_ATTR_DISPATCH).to be_frozen
    expect(Metanorma::Oiml::Sts::Transformer::IdGenerator::IdWalk::WALK_ATTRS)
      .to eq(described_class::TYPED_ATTR_DISPATCH.keys)
  end

  it "binds every dispatched attribute and block class to an existing handler" do
    described_class::TYPED_ATTR_DISPATCH.each_value do |handler|
      expect(described_class.method_defined?(handler) ||
              described_class.private_method_defined?(handler))
        .to be(true), "no handler ##{handler} for the typed attribute dispatch"
    end
    described_class::HANDLERS.each_value do |handler|
      expect(described_class.method_defined?(handler) ||
              described_class.private_method_defined?(handler))
        .to be(true), "no handler ##{handler} for #{described_class::HANDLERS.key(handler)}"
    end
  end
end
