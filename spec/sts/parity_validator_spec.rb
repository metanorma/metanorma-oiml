# frozen_string_literal: true

require "spec_helper"

RSpec.describe Metanorma::Oiml::Sts::ParityValidator do
  let(:mn_html) { "<html><body><h2>1 Scope</h2><p>Hello world</p></body></html>" }
  let(:sts_html) { "<html><body><h2>Scope</h2><p>Hello world</p></body></html>" }

  let(:report) do
    described_class.validate(mn_html: mn_html, sts_html: sts_html)
  end

  it "reports high word coverage when content is present" do
    expect(report.word_coverage_percent).to be > 20.0
  end

  it "reports missing paragraphs when STS is empty" do
    r = described_class.validate(mn_html: mn_html, sts_html: "<html></html>")
    expect(r.missing_paragraphs).to include("hello world")
  end

  it "passes when all content is present" do
    expect(report.pass?).to be true
  end

  it "includes missing headings in report" do
    r = described_class.validate(
      mn_html: "<html><body><h2>1 Introduction</h2></body></html>",
      sts_html: "<html><body><h2>Scope</h2></body></html>"
    )
    expect(r.missing_headings).to include("introduction")
  end
end
