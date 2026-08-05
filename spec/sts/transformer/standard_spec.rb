# frozen_string_literal: true

# The Standard adapter conforms metanorma-oiml's STS transformer to the
# metanorma-core Processor#document_transformers contract (metanorma-core#12).
RSpec.describe Metanorma::Oiml::Sts::Transformer::Standard do
  let(:xml) { File.read(FIXTURES_ROOT.join("sample.xml")) }
  let(:model) do
    Metanorma::Oiml::Sts::Transformer::SourceDocument.from_xml(xml)
  end

  it "yields a target responding to #to_xml (String)" do
    target = described_class.new(model, {}).transform
    expect(target.to_xml).to be_a(String)
  end

  it "produces output identical to the standalone Transformer.convert" do
    via_adapter = described_class.new(model).transform.to_xml
    expect(via_adapter).to eq(Metanorma::Oiml::Sts::Transformer.convert(xml))
  end
end
