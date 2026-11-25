# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Metanorma::Oiml::Sts::Transformer::NbspProcessor do
  let(:nbsp) { ' ' }

  it 'binds labels to their numbers' do
    expect(described_class.process('Table 5 and Figure A.1')).to eq(
      "Table#{nbsp}5 and Figure#{nbsp}A.1"
    )
  end

  it 'binds numbers to percent and Annex to its letter' do
    expect(described_class.process('10 % in Annex B'))
      .to eq("10#{nbsp}% in Annex#{nbsp}B")
  end

  it 'leaves non-strings alone' do
    expect(described_class.process(nil)).to be_nil
  end

  it 'rewrites text nodes only, never tags or attributes' do
    xml = '<p id="Table 5">See Table 5</p>'
    expect(described_class.apply_to_text(xml))
      .to eq("<p id=\"Table 5\">See Table#{nbsp}5</p>")
  end
end
