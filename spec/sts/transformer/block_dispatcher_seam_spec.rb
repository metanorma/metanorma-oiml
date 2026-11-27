# frozen_string_literal: true

require "open3"

RSpec.describe Metanorma::Oiml::Sts::Transformer::BlockDispatcher do
  # metanorma/metanorma-oiml#44: a mirrored IdGenerator evaluated
  # BlockDispatcher::TYPED_ATTR_DISPATCH at load time
  # (IdGenerator::IdWalk::WALK_ATTRS); an OIML dispatcher without that table
  # broke the whole suite at load. The OIML classes must stay on the shared
  # engine's dispatcher and id walk, not drift into local copies.
  let(:engine) { Metanorma::Document::Sts::Transformer }
  let(:oiml_ids) { Metanorma::Oiml::Sts::Transformer::IdGenerator }

  it "inherits the engine dispatch table rather than a local copy" do
    expect(described_class.superclass).to equal(engine::BlockDispatcher)
    expect(described_class::TYPED_ATTR_DISPATCH).to be_frozen
    expect(described_class::TYPED_ATTR_DISPATCH).to equal(engine::BlockDispatcher::TYPED_ATTR_DISPATCH)
  end

  it "walks ids with the engine id walk over the same dispatch keys" do
    expect(oiml_ids.superclass).to equal(engine::IdGenerator)
    expect(oiml_ids::IdWalk).to equal(engine::IdGenerator::IdWalk)
    expect(oiml_ids::IdWalk::WALK_ATTRS).to eq(described_class::TYPED_ATTR_DISPATCH.keys)
  end

  it "loads the STS library in a fresh process" do
    out, status = Open3.capture2e(RbConfig.ruby, "-Ilib", "-e", 'require "metanorma/oiml/sts"')
    expect(status).to be_success, out.lines.last(5).join
  end

  it "binds every dispatched attribute and block class to an existing handler" do
    described_class::TYPED_ATTR_DISPATCH.each_value do |handler|
      expect(described_class.method_defined?(handler) ||
              described_class.private_method_defined?(handler))
        .to be(true), "no handler ##{handler} for the typed attribute dispatch"
    end
    described_class::MODEL_CLASS_DISPATCH.each_value do |handler|
      expect(described_class.method_defined?(handler) ||
              described_class.private_method_defined?(handler))
        .to be(true), "no handler ##{handler} for #{described_class::MODEL_CLASS_DISPATCH.key(handler)}"
    end
  end
end
