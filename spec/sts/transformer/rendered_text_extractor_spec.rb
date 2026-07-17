# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor do
  let(:described_class) { Metanorma::Oiml::Sts::Transformer::RenderedTextExtractor }

  def build_paragraph_xml(content)
    <<~XML
      <p xmlns="https://www.metanorma.org/ns/standoc">#{content}</p>
    XML
  end

  def parse_paragraph(content)
    Metanorma::Document::Components::Paragraphs::ParagraphBlock.from_xml(
      build_paragraph_xml(content)
    )
  end

  describe ".text_of" do
    it "returns empty string for nil" do
      expect(described_class.text_of(nil)).to eq("")
    end

    it "returns the string itself for string input" do
      expect(described_class.text_of("hello")).to eq("hello")
    end

    it "extracts plain text from a paragraph" do
      p = parse_paragraph("hello world")
      expect(described_class.text_of(p)).to eq("hello world")
    end

    it "extracts text with surrounding spaces for stem elements" do
      xml = <<~XML
        <p xmlns="https://www.metanorma.org/ns/standoc">capacity (<stem block="false" type="MathML">
          <math xmlns="http://www.w3.org/1998/Math/MathML"><msub><mi>E</mi><mtext>max</mtext></msub></math>
          <asciimath>E_{"max"}</asciimath>
        </stem>)</p>
      XML
      p = Metanorma::Document::Components::Paragraphs::ParagraphBlock.from_xml(xml)
      text = described_class.text_of(p)
      expect(text).to include("capacity")
      expect(text).to include("E max")
    end

    it "deduplicates stems visited via multiple typed-model paths" do
      xml = <<~XML
        <p xmlns="https://www.metanorma.org/ns/standoc">(<stem block="false" type="MathML">
          <math xmlns="http://www.w3.org/1998/Math/MathML"><mi>x</mi></math>
          <asciimath>x</asciimath>
        </stem>)</p>
      XML
      p = Metanorma::Document::Components::Paragraphs::ParagraphBlock.from_xml(xml)
      text = described_class.text_of(p)
      count = text.scan(/\bx\b/).size
      expect(count).to eq(1)
    end

    it "extracts xref visible text via target fallback" do
      xml = <<~XML
        <p xmlns="https://www.metanorma.org/ns/standoc">see <xref target="sec-3.5"/></p>
      XML
      p = Metanorma::Document::Components::Paragraphs::ParagraphBlock.from_xml(xml)
      text = described_class.text_of(p)
      expect(text).to include("3.5")
    end
  end
end
