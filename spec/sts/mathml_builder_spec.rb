# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Oiml::Sts::MathmlBuilder do
  describe ".mathml_for" do
    it "converts asciimath to MathML fragment" do
      result = described_class.mathml_for("n_{\"LC\"}")
      expect(result).to include("<msub>")
      expect(result).to include("<mi>n</mi>")
      expect(result).to include("<mtext>LC</mtext>")
    end

    it "returns nil for empty input" do
      expect(described_class.mathml_for("")).to be_nil
      expect(described_class.mathml_for(nil)).to be_nil
    end
  end

  describe ".asciimath_to_plain_text" do
    it "converts subscripts with space prefix" do
      expect(described_class.asciimath_to_plain_text("n_{\"LC\"}"))
        .to eq("n LC")
    end

    it "converts superscripts without space" do
      expect(described_class.asciimath_to_plain_text("x^{2}"))
        .to eq("x2")
    end

    it "converts math symbols" do
      expect(described_class.asciimath_to_plain_text("a le b"))
        .to eq("a ≤ b")
    end

    it "converts <= to ≤" do
      expect(described_class.asciimath_to_plain_text("0 <= m"))
        .to eq("0 ≤ m")
    end

    it "converts >= to ≥" do
      expect(described_class.asciimath_to_plain_text("m >= 50"))
        .to eq("m ≥ 50")
    end

    it "converts != to ≠" do
      expect(described_class.asciimath_to_plain_text("a != b"))
        .to eq("a ≠ b")
    end

    it "converts -> to →" do
      expect(described_class.asciimath_to_plain_text("x -> y"))
        .to eq("x → y")
    end

    it "converts => to ⇒" do
      expect(described_class.asciimath_to_plain_text("p => q"))
        .to eq("p ⇒ q")
    end

    it "handles chained inequalities" do
      expect(described_class.asciimath_to_plain_text("0 <= m <= 50"))
        .to eq("0 ≤ m ≤ 50")
    end
  end

  describe ".mathml_to_plain_text" do
    it "extracts text from MathML preserving decimal commas" do
      mathml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mn>0,1</mn>
        </math>
      XML
      expect(described_class.mathml_to_plain_text(mathml)).to eq("0,1")
    end

    it "extracts subscripts from MathML preserving case" do
      mathml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <msub><mi>E</mi><mtext>max</mtext></msub>
        </math>
      XML
      text = described_class.mathml_to_plain_text(mathml)
      expect(text).to include("E")
      expect(text).to include("max")
    end

    it "preserves Unicode operators from MathML" do
      mathml = <<~XML
        <math xmlns="http://www.w3.org/1998/Math/MathML">
          <mi>x</mi><mo>≤</mo><mi>y</mi>
        </math>
      XML
      expect(described_class.mathml_to_plain_text(mathml)).to include("≤")
    end

    it "returns empty string for nil" do
      expect(described_class.mathml_to_plain_text(nil)).to eq("")
    end
  end
end
