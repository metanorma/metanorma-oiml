# frozen_string_literal: true

require "spec_helper"
require "fileutils"
require "tmpdir"

RSpec.describe Metanorma::Oiml::Sts::HtmlRenderer::Ruby do
  subject(:renderer) { described_class.new }

  let(:xml) do
    <<~XML
      <standard>
        <front><iso-meta>
          <title-wrap><main>Test Document</main></title-wrap>
          <std-ident>
            <originator>OIML X</originator>
            <doc-number>999</doc-number>
          </std-ident>
        </iso-meta></front>
        <body>
          <sec id="s1">
            <title>First</title>
            <p>Text with <bold>bold</bold> and <italic>italic</italic> &amp; entities.</p>
            <list list-type="bullet">
              <list-item><p>one</p></list-item>
              <list-item><p>two</p></list-item>
            </list>
            <list list-type="order">
              <list-item><p>first</p></list-item>
            </list>
          </sec>
          <sec id="s2">
            <title>Second</title>
            <table-wrap><table>
              <thead><tr><th>h1</th><th>h2</th></tr></thead>
              <tbody><tr><td>a</td><td>b</td></tr></tbody>
            </table></table-wrap>
          </sec>
        </body>
      </standard>
    XML
  end

  let(:html) { renderer.render(xml) }

  def normalized
    html.gsub(/\s+/, " ")
  end

  it "renders the meta header with title and doc id in fragment mode" do
    fragment = renderer.render(xml, full_document: false).gsub(/\s+/, " ")
    expect(fragment).to include('<header><span class="doc-id">OIML X 999</span>' \
                                '<span class="title">Test Document</span></header>')
  end

  it "renders sections" do
    expect(html).to include('<section id="s1" class="frontmatter">')
  end

  it "marks unnumbered top-level sections as front matter" do
    expect(html).to include('<section id="s1" class="frontmatter">')
    expect(html).to include('<section id="s2" class="frontmatter">')
  end

  it "prefixes numbered section headings with their label" do
    numbered = renderer.render(
      '<standard><body><sec id="sc"><label>1</label><title>Scope</title><p>x</p></sec></body></standard>',
      full_document: false,
    )
    expect(numbered).to include('<h2><span class="sec-label">1</span> Scope<a class="h-anchor"')
    expect(numbered).not_to include('class="frontmatter"')
  end

  it "numbers TOC entries with the section label" do
    numbered = renderer.render(
      '<standard><body><sec id="sc"><label>1</label><title>Scope</title><p>x</p></sec></body></standard>',
    ).gsub(/\s+/, " ")
    expect(numbered).to include('href="#sc">1 Scope</a>')
  end

  it "renders list item labels as markers without HTML bullets" do
    labeled = renderer.render(
      '<standard><body><sec><title>S</title><list list-type="bullet">' \
      "<list-item><label>—</label><p>one</p></list-item>" \
      "</list></sec></body></standard>",
      full_document: false,
    )
    expect(labeled).to include('<ul class="mn-labeled-list">')
    expect(labeled).to include("<li><span class=\"li-label\">—</span>")
    expect(labeled).not_to include('<span class="label">—</span>')
  end

  it "renders the table caption band above the table" do
    captioned = renderer.render(
      '<standard><body><sec><title>S</title><table-wrap><label>Table 1</label>' \
      "<caption><title>Cap</title></caption>" \
      "<table><tbody><tr><td>a</td></tr></tbody></table></table-wrap></sec></body></standard>",
      full_document: false,
    ).gsub(/\s+/, " ")
    expect(captioned).to include(
      '<p class="tbl-caption"><span class="tc-label">Table 1</span>' \
      "<span class=\"tc-delim\"> — </span>Cap</p>",
    )
    expect(captioned.scan("Table 1").size).to eq(1)
  end

  it "renders titles with an anchor link" do
    expect(html).to include('<h2>First<a class="h-anchor" href="#s1"')
  end

  it "includes an interactive table of contents" do
    expect(normalized).to include('<nav id="toc" class="toc-panel')
  end

  it "links TOC entries to sections" do
    expect(normalized).to include('<li><a class="toc-link toc-link-d0" href="#s1">First</a></li>')
  end

  it "nests deeper section titles at deeper heading levels" do
    nested = renderer.render(
      "<standard><body><sec id=\"a\"><title>A</title><sec id=\"b\"><title>B</title><p>x</p></sec></sec></body></standard>",
      full_document: false,
    )
    expect(nested).to include("<h3>B<a class=\"h-anchor\" href=\"#b\"")
  end

  it "renders paragraphs with inline markup and escaped text" do
    expect(normalized).to include("<p>Text with <strong>bold</strong> and " \
                                  "<em>italic</em> &amp; entities.</p>")
  end

  it "renders an unordered list from bullet list-type" do
    expect(html.scan("<ul>").size).to eq(1)
  end

  it "renders an ordered list from order list-type" do
    expect(html.scan("<ol>").size).to eq(1)
  end

  it "renders each list item exactly once" do
    expect(html.scan("<li><p").size).to eq(3)
  end

  it "renders the bibliography with inline std markup, no headings" do
    bib = renderer.render(
      "<standard><back><ref-list><ref><label>[1]</label><std><std-ref>Some Org Standard</std-ref><title>Full Title</title></std></ref></ref-list></back></standard>",
      full_document: false,
    )
    expect(bib).not_to include("<h2>Full Title</h2>")
  end

  it "renders a table wrapper with a table" do
    expect(html).to include('<div class="table-wrap"><table>')
  end

  it "renders table header cells" do
    expect(html).to include("<th>h1</th>")
  end

  it "renders table body cells exactly once" do
    expect(html.scan("<td>").size).to eq(2)
  end

  it "accepts a parsed sts-ruby model without re-parsing" do
    model = Sts::NisoSts::Standard.from_xml(xml)
    expect(renderer.render(model)).to eq(html)
  end

  it "does not use Nokogiri" do
    source = File.read(described_class.instance_method(:render).source_location.first)
    expect(source).not_to include('require "nokogiri"')
  end

  it "assembles a full document by default" do
    expect(normalized).to include("<!DOCTYPE html>")
  end

  it "brands the document with the beige site nav" do
    expect(normalized).to include('class="site-nav ')
  end

  it "includes a breadcrumb integrated with the TOC" do
    expect(normalized).to include('class="breadcrumb ')
  end

  it "includes a light/dark theme toggle" do
    expect(normalized).to include('id="theme-toggle"')
  end

  it "adds a site footer" do
    expect(normalized).to include('class="site-footer ')
  end

  it "carries the doc id in the brand header" do
    expect(normalized).to include('<span class="crumb-doc ')
  end

  it "carries the title in the brand header" do
    expect(normalized).to include('class="crumb-title ')
  end

  it "renders a bare fragment with full_document: false" do
    fragment = renderer.render(xml, full_document: false)
    expect(fragment).not_to include("<!DOCTYPE html>")
  end

  it "renders through the HtmlRenderer module entry point" do
    expect(Metanorma::Oiml::Sts::HtmlRenderer.render(xml)).to include("<!DOCTYPE html>")
  end

  it "supports template overrides via templates_dir" do
    Dir.mktmpdir do |dir|
      FileUtils.cp(Dir.glob(File.join(described_class::TEMPLATES_DIR, "*.liquid")), dir)
      File.write(File.join(dir, "_element.html.liquid"),
                 "<{{ tag }} data-x=\"1\">{{ content }}</{{ tag }}>\n")
      custom = described_class.new(templates_dir: dir).render(xml)
      expect(custom).to include('<p data-x="1">')
    end
  end
end
