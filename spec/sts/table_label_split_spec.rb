# frozen_string_literal: true

require_relative '../spec_helper'

# A legacy presentation table names itself "Table N — title" with no autonum;
# the STS label is the "Table N" part and the caption title is the rest.
# Ported from metanorma-iso#1890.
RSpec.describe 'table label split' do # rubocop:disable Metrics/BlockLength
  let(:name) { 'Table 2 — Parts of a provision class' }

  let(:xml) do
    <<~XML
      <metanorma>
        <bibdata>
          <title language="en" type="main">T</title>
          <docidentifier>OIML R 1</docidentifier>
          <language>en</language>
        </bibdata>
        <sections>
          <clause id="c1">
            <title>Body</title>
            <table id="tb1">
              <name>#{name}</name>
              <tbody>
                <tr><th>H</th><td>Cell</td></tr>
              </tbody>
            </table>
          </clause>
        </sections>
      </metanorma>
    XML
  end

  let(:doc) { Nokogiri::XML(Metanorma::Oiml::Sts.convert(xml)) }
  let(:label) { doc.at('//body//table-wrap/label')&.text }
  let(:title) { doc.at('//body//table-wrap/caption/title')&.text }

  it 'moves the leading table number into <label>' do
    expect(label).to eq('Table 2')
  end

  it 'keeps the remainder of the name as the caption title' do
    expect(title).to eq('Parts of a provision class')
  end

  context 'when the title itself contains an em dash' do
    let(:name) { 'Table 2 — Parts — of a class' }

    it 'splits only at the first separator' do
      expect([label, title]).to eq(['Table 2', 'Parts — of a class'])
    end
  end

  context 'with a dotted number and no spaces around the em dash' do
    let(:name) { 'Table 1.1—Scope' }

    it 'splits the label and title' do
      expect([label, title]).to eq(['Table 1.1', 'Scope'])
    end
  end

  context 'with a bare hyphen between two numbers' do
    let(:name) { 'Table 1-2 Scope' }

    it 'keeps the whole name as the title, since it is a range' do
      expect([label, title]).to eq([nil, 'Table 1-2 Scope'])
    end
  end
end
