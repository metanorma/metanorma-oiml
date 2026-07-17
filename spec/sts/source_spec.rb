# frozen_string: true

require "spec_helper"
require "metanorma/document"
require "metanorma/oiml/sts/source/paragraph"
require "metanorma/oiml/sts/source/section"

RSpec.describe Metanorma::Oiml::Sts::Source do
  describe ".wrap" do
    it "returns nil for nil input" do
      expect(described_class.wrap(nil)).to be_nil
    end

    it "returns the same object if already an adapter" do
      adapter = described_class::Base.new("test")
      expect(described_class.wrap(adapter)).to be(adapter)
    end

    it "wraps a ParagraphBlock in a Paragraph adapter" do
      typed = Metanorma::Document::Components::Paragraphs::ParagraphBlock.new
      adapter = described_class.wrap(typed)
      expect(adapter).to be_a(described_class::Paragraph)
    end

    it "wraps an IsoClauseSection in a Section adapter" do
      typed = Metanorma::IsoDocument::Sections::IsoClauseSection.new
      adapter = described_class.wrap(typed)
      expect(adapter).to be_a(described_class::Section)
    end
  end

  describe Metanorma::Oiml::Sts::Source::Registry do
    it "finds adapter by exact class name" do
      adapter = described_class.adapter_for(
        Metanorma::Document::Components::Paragraphs::ParagraphBlock
      )
      expect(adapter).to eq(Metanorma::Oiml::Sts::Source::Paragraph)
    end

    it "finds adapter by ancestor class" do
      # IsoForewordSection inherits from ContentSection, not IsoClauseSection.
      # The registry walks the ancestor chain.
      typed = Metanorma::IsoDocument::Sections::IsoClauseSection.new
      adapter = described_class.adapter_for(typed.class)
      expect(adapter).to eq(Metanorma::Oiml::Sts::Source::Section)
    end

    it "returns nil for unregistered classes" do
      adapter = described_class.adapter_for(String)
      expect(adapter).to be_nil
    end
  end

  describe Metanorma::Oiml::Sts::Source::InlineExtractor do
    it "extracts text from a String" do
      expect(described_class.text_from("hello")).to eq("hello")
    end

    it "extracts text from an Array" do
      expect(described_class.text_from(["a", "b"])).to eq("ab")
    end

    it "extracts text from nil" do
      expect(described_class.text_from(nil)).to eq("")
    end
  end
end
