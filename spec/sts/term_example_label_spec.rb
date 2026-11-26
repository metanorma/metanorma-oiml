# frozen_string_literal: true

# A term example with body paragraphs converts with the "Example: "
# designation prefixed to the first paragraph's text, instead of
# crashing (the trunk addressed Sts::NisoSts::Paragraph#content, which
# does not exist, and an in-place attribute write on a parsed
# paragraph duplicates the captured raw text at serialization — the
# paragraph is rebuilt fresh instead).
RSpec.describe "term example label prefix" do
  let(:xml) do
    <<~XML
      <metanorma>
        <bibdata>
          <title language="en" type="main">T</title>
          <docidentifier>OIML R 60:2025</docidentifier>
          <language>en</language>
        </bibdata>
        <sections>
          <terms id="t1">
            <title>Terms and definitions</title>
            <term id="tm1">
              <preferred><expression><name>load cell</name></expression></preferred>
              <termexample id="ex1">
                <p id="p1">To preserve stored data</p>
              </termexample>
            </term>
          </terms>
        </sections>
      </metanorma>
    XML
  end

  let(:doc) { Nokogiri::XML(Metanorma::Oiml::Sts.convert(xml)) }

  it "prefixes the example designation to the first paragraph text" do
    texts = doc.xpath("//term//p | //sec//p").map(&:text)
    expect(texts).to include(a_string_starting_with("Example:"))
    expect(texts.join).to include("To preserve stored data")
  end

  it "does not duplicate the paragraph text" do
    texts = doc.xpath("//term//p | //sec//p").map(&:text)
    expect(texts.join.scan("To preserve stored data").size).to eq(1)
  end
end
