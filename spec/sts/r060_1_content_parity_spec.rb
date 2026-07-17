# frozen_string_literal: true

# Real document content parity test for OIML R 60-1:2021.
require "spec_helper"
require "pathname"
require "set"

RSpec.describe "OIML R 60-1:2021 content parity", :real_document_parity do
  SAMPLES_ROOT = Pathname.new(ENV.fetch("MN_SAMPLES_OIML",
                                        File.expand_path("~/src/mn/mn-samples-oiml")))
  PRES_XML = SAMPLES_ROOT.join("_site/documents/r060/1/document.presentation.xml")
  MN_HTML  = SAMPLES_ROOT.join("_site/documents/r060/1/document.html")

  skip "R 60-1 presentation XML not found at #{PRES_XML}" unless PRES_XML.exist?
  skip "R 60-1 Metanorma HTML not found at #{MN_HTML}" unless MN_HTML.exist?

  let(:source_xml) { PRES_XML.read }
  let(:mn_html_raw) { MN_HTML.read }
  let(:sts_xml) { Metanorma::Oiml::Sts.convert(source_xml) }
  let(:renderer) { Metanorma::Oiml::Sts::HtmlRenderer::Xslt.new }
  let(:sts_html) { renderer.render(sts_xml) }

  let(:mn_content) { strip_chrome(mn_html_raw) }

  def strip_chrome(html)
    doc = Nokogiri::HTML(html)
    doc.css("script, style, head, nav, .title-section, .prefatory-section,
             .toc, #toc, .coverpage_docnumber, .coverpage_techcommittee,
             .coverpage_docstage, .coverpage_warning, .doctitle-fr,
             .btn, .collapse-button, .collapse-group").remove
    doc.css("body").first.to_html
  end

  # Normalize text: insert space between block elements so words don't
  # concatenate when block text is joined; unify dashes; lowercase.
  def normalize(t)
    t.to_s
     .gsub(/(<\/(?:p|div|td|th|li|h[1-6]|section|table|tr|ul|ol|dl|dt|dd)>)/i, " \\1")
     .gsub(/[\s ]+/, " ")
     .gsub(/[–—−]/, "-")
     .gsub(/\s+/, " ")
     .strip
     .downcase
  end

  # --- Coverage metrics ---

  def word_coverage(mn_text, sts_text)
    mn_words = mn_text.split.to_set
    sts_words = sts_text.split.to_set
    return 100.0 if mn_words.empty?

    covered = mn_words.count { |w| sts_words.include?(w) }
    (covered.to_f * 100.0 / mn_words.size).round(2)
  end

  def unique_paragraph_coverage(mn_doc, sts_doc)
    mn_paras = mn_doc.css("p").map { |p| normalize(p.text) }.reject(&:empty?).reject { |p| p.length < 30 }.to_set
    sts_paras = sts_doc.css("p").map { |p| normalize(p.text) }.reject(&:empty?).to_set
    return 100.0 if mn_paras.empty?

    covered = mn_paras.count { |p| sts_paras.include?(p) }
    (covered.to_f * 100.0 / mn_paras.size).round(2)
  end

  # --- Tests ---

  it "STS XML has correct structural element counts" do
    expect(sts_xml.scan(/<sec[\s>]/).size).to be >= 60
    expect(sts_xml.scan(/<table-wrap[\s>]/).size).to eq(6)
    expect(sts_xml.scan(/<fig[\s>]/).size).to eq(4)
    expect(sts_xml.scan(/<ref[\s>]/).size).to eq(6)
  end

  it "STS HTML contains the document title" do
    sts_text = Nokogiri::HTML(sts_html).text
    expect(sts_text).to include("Metrological regulation for load cells")
  end

  it "STS HTML contains the OIML document identifier" do
    sts_text = Nokogiri::HTML(sts_html).text
    expect(sts_text).to match(/OIML\s*R/)
    expect(sts_text).to match(/60/)
  end

  it "STS HTML contains all major section headings" do
    sts_text = normalize(Nokogiri::HTML(sts_html).text)
    %w[foreword introduction scope terminology description metrological technical].each do |h|
      expect(sts_text).to include(h), "Expected heading '#{h}' in STS HTML"
    end
  end

  it "STS HTML bibliography includes all cited OIML docs" do
    sts_text = Nokogiri::HTML(sts_html).text
    %w[OIML V 1 OIML V 2-200 OIML D 9 OIML D 11 OIML B 18].each do |ref|
      expect(sts_text).to include(ref), "Expected '#{ref}' in STS HTML"
    end
  end

  it "STS HTML has at least one figure caption" do
    sts_doc = Nokogiri::HTML(sts_html)
    captions = sts_doc.css("figcaption, figure").map { |f| f.text.strip }.reject(&:empty?)
    expect(captions.size).to be > 0
  end

  it "STS HTML has all 4 graphics" do
    sts_doc = Nokogiri::HTML(sts_html)
    imgs = sts_doc.css("img").map { |i| i["src"] }.reject(&:empty?)
    expect(imgs.size).to eq(4)
  end

  it "STS HTML has all 6 tables with content" do
    sts_doc = Nokogiri::HTML(sts_html)
    tables = sts_doc.css("table")
    expect(tables.size).to eq(6)
    tables.each do |t|
      expect(t.css("tr").size).to be > 0
    end
  end

  it "STS HTML word-level coverage of Metanorma HTML is at least 75%" do
    mn_doc = Nokogiri::HTML(mn_content)
    sts_doc = Nokogiri::HTML(sts_html)
    mn_text = normalize(mn_doc.text)
    sts_text = normalize(sts_doc.text)
    coverage = word_coverage(mn_text, sts_text)
    expect(coverage).to be >= 75.0,
                        "Word coverage was #{coverage}% (threshold 75%)"
  end

  it "STS HTML paragraph-level coverage is at least 60%" do
    mn_doc = Nokogiri::HTML(mn_content)
    sts_doc = Nokogiri::HTML(sts_html)
    coverage = unique_paragraph_coverage(mn_doc, sts_doc)
    expect(coverage).to be >= 60.0,
                        "Paragraph coverage was #{coverage}% (threshold 60%)"
  end

  it "STS HTML contains all key terms from R 60-1" do
    sts_text = Nokogiri::HTML(sts_html).text
    key_terms = [
      "load cell",
      "accuracy class",
      "verification",
      "metrological",
      "maximum permissible",
      "humidity",
      "temperature",
      "strain gauge",
      "manufacture"
    ]
    key_terms.each do |term|
      expect(sts_text.downcase).to include(term.downcase),
             "Expected key term '#{term}' in STS HTML"
    end
  end
end
