# frozen_string: true

require "spec_helper"
require "nokogiri"
require "pathname"

RSpec.describe "OIML STS HTML layout" do
  SAMPLES_ROOT = Pathname.new(File.expand_path("~/src/mn/mn-samples-oiml"))
  PRES_XML = SAMPLES_ROOT.join("_site/documents/r060/1/document.presentation.xml")

  let(:sts_xml) { Metanorma::Oiml::Sts.convert(PRES_XML.read) }
  let(:sts_html) { Metanorma::Oiml::Sts::HtmlRenderer::Xslt.new.render(sts_xml) }
  let(:html_doc) { Nokogiri::HTML(sts_html) }

  before { skip "fixture missing" unless PRES_XML.exist? }

  describe "document shell" do
    it "emits a complete HTML document" do
      expect(html_doc.css("html")).not_to be_empty
      expect(html_doc.css("head title")).not_to be_empty
      expect(html_doc.css("body")).not_to be_empty
    end

    it "embeds CSS in the head" do
      head = html_doc.at_css("head")
      expect(head.at_css("style")).not_to be_nil
    end

    it "includes viewport meta for responsive layout" do
      expect(html_doc.at_css('meta[name="viewport"]')).not_to be_nil
    end
  end

  describe "front matter" do
    it "renders doc-meta header with doc-id badge" do
      header = html_doc.at_css("header.doc-meta")
      expect(header).not_to be_nil
      expect(header.at_css(".doc-id")).not_to be_nil
    end

    it "renders the document title as h1" do
      title = html_doc.at_css("h1.title")
      expect(title).not_to be_nil
      expect(title.text).to include("Metrological regulation")
    end
  end

  describe "headings hierarchy" do
    it "uses h1 for top-level sections" do
      top_h1 = html_doc.css("section > h1").to_a
      expect(top_h1.size).to be > 5
    end

    it "uses h2 for nested sections" do
      h2 = html_doc.css("section section > h2").to_a
      expect(h2.size).to be > 5
    end
  end

  describe "tables" do
    it "renders every table-wrap with proper table structure" do
      html_doc.css("table-wrap").each do |wrap|
        table = wrap.at_css("table")
        expect(table).not_to be_nil
        expect(table.at_css("thead, tbody")).not_to be_nil
      end
    end
  end

  describe "bibliography" do
    it "renders refs as p.biblio with hanging indent" do
      refs = html_doc.css("p.biblio")
      expect(refs.size).to be > 0
    end
  end

  describe "definition lists" do
    it "renders def-list as dl with dt/dd pairs" do
      dls = html_doc.css("dl")
      expect(dls.size).to be > 0
      dl = dls.first
      expect(dl.at_css("dt")).not_to be_nil
      expect(dl.at_css("dd")).not_to be_nil
    end
  end
end
