# frozen_string_literal: true

require "spec_helper"
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

  it "renders the meta header with title and doc id" do
    expect(normalized).to include('<header><span class="doc-id">OIML X 999</span>' \
                                  '<span class="title">Test Document</span></header>')
  end

  it "renders sections" do
    expect(html).to include('<section id="s1">')
  end

  it "renders titles" do
    expect(html).to include("<h2>First</h2>")
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
    expect(html.scan("<li>").size).to eq(3)
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
    model = Sts::IsoSts::Standard.from_xml(xml)
    expect(renderer.render(model)).to eq(html)
  end

  it "does not use Nokogiri" do
    source = File.read(described_class.instance_method(:render).source_location.first)
    expect(source).not_to include('require "nokogiri"')
  end

  it "supports template overrides via templates_dir" do
    Dir.mktmpdir do |dir|
      %w[_element.html.liquid _img.html.liquid _link.html.liquid
         _meta_header.html.liquid].each do |t|
        src = File.join(described_class::TEMPLATES_DIR, t)
        File.write(File.join(dir, t), File.read(src))
      end
      File.write(File.join(dir, "_element.html.liquid"),
                 "<{{ tag }} data-x=\"1\">{{ content }}</{{ tag }}>\n")
      custom = described_class.new(templates_dir: dir).render(xml)
      expect(custom).to include('<p data-x="1">')
    end
  end
end
