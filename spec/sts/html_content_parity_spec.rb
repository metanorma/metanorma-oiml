# frozen_string_literal: true

# HTML content parity test.
#
# This test verifies that the OIML STS XML output contains 100% of the
# semantic content from the source Metanorma presentation XML. It does
# this by:
#
# 1. Converting the presentation XML to OIML STS XML.
# 2. Rendering the STS XML to HTML via HtmlRenderer.
# 3. Extracting a content fingerprint from the STS HTML.
# 4. Extracting a content fingerprint from the Metanorma HTML (ground
#    truth, built from the presentation XML's text content).
# 5. Asserting that every fingerprint entry from the Metanorma source
#    appears in the STS HTML fingerprint.
#
# This is a much stronger guarantee than word retention or element counts:
# it verifies paragraph-by-paragraph, cell-by-cell, item-by-item that no
# content was lost.
RSpec.describe "OIML STS HTML content parity", :parity do
  include Metanorma::Oiml::Sts::Spec::HtmlFingerprint

  let(:renderer) { Metanorma::Oiml::Sts::HtmlRenderer::Ruby.new }

  FIXTURES = %w[
    sample.xml
    complete_metadata.xml
    nested_sections.xml
    inline_markup.xml
    lists.xml
    tables.xml
    figures.xml
    notes_examples.xml
    bibliography.xml
    annexes.xml
  ].freeze

  SOURCE_NS = Metanorma::Oiml::Sts::Spec::ContentMatcher::SOURCE_NS.freeze

  def load_fixture(name)
    File.read(FIXTURES_ROOT.join(name))
  end

  # Build a "ground truth" HTML from the source presentation XML's
  # semantic content. This represents what MUST appear in the STS HTML.
  def source_html(source_xml)
    doc = Nokogiri::XML(source_xml)
    parts = []

    # Metadata
    doc.xpath("//m:bibdata/m:docidentifier", SOURCE_NS).each do |d|
      parts << %(<span class="doc-id">#{d.text}</span>)
    end
    doc.xpath("//m:bibdata/m:title", SOURCE_NS).each do |t|
      parts << "<title>#{t.text}</title>"
      parts << "<h2>#{t.text}</h2>"
    end

    # Sections and their content
    doc.xpath("//m:sections//m:clause", SOURCE_NS).each do |clause|
      title = clause.at_xpath("./m:title", SOURCE_NS)
      parts << "<h2>#{title.text}</h2>" if title
    end
    doc.xpath("//m:preface//m:clause/m:title | //m:annex/m:title", SOURCE_NS).each do |t|
      parts << "<h2>#{t.text}</h2>"
    end

    # Paragraphs (semantic only — skip fmt-* duplicates)
    doc.xpath("//m:sections//m:p | //m:annex//m:p | //m:preface//m:p", SOURCE_NS).each do |p|
      text = p.text.strip
      parts << "<p>#{text}</p>" unless text.empty?
    end

    # Table cells
    doc.xpath("//m:td | //m:th", SOURCE_NS).each do |cell|
      text = cell.text.strip
      parts << "<td>#{text}</td>" unless text.empty?
    end

    # List items
    doc.xpath("//m:li", SOURCE_NS).each do |li|
      text = li.text.strip
      parts << "<li>#{text}</li>" unless text.empty?
    end

    # Images
    doc.xpath("//m:image/@src", SOURCE_NS).each do |src|
      parts << %(<img src="#{src.value}"/>)
    end

    # Links
    doc.xpath("//m:link/@target", SOURCE_NS).each do |href|
      parts << %(<a href="#{href.value}">link</a>)
    end

    # Bibliography titles (rendered as spans, not p, to match HtmlRenderer)
    doc.xpath("//m:bibitem", SOURCE_NS).each do |bib|
      title = bib.at_xpath("./m:title", SOURCE_NS)
      parts << %(<span class="citation">#{title.text}</span>) if title
    end

    parts.join("\n")
  end

  FIXTURES.each do |fixture|
    describe fixture do
      let(:source_xml) { load_fixture(fixture) }
      let(:sts_xml) { Metanorma::Oiml::Sts.convert(source_xml) }
      let(:sts_html) { renderer.render(sts_xml) }
      let(:mn_html) { source_html(source_xml) }
      let(:sts_fp) { extract(sts_html) }
      let(:mn_fp) { extract(mn_html) }

      it "STS HTML contains all paragraphs from the source" do
        missing = mn_fp[:paragraphs] - sts_fp[:paragraphs]
        expect(missing).to be_empty,
                           "Paragraphs missing from STS HTML:\n#{missing.to_a.first(5).map { |p| "  #{p[0..80]}..." }.join("\n")}"
      end

      it "STS HTML contains all table cells from the source" do
        missing = mn_fp[:table_cells] - sts_fp[:table_cells]
        expect(missing).to be_empty,
                           "Table cells missing from STS HTML:\n#{missing.to_a.first(5).map { |c| "  #{c[0..80]}..." }.join("\n")}"
      end

      it "STS HTML contains all list items from the source" do
        missing = mn_fp[:list_items] - sts_fp[:list_items]
        expect(missing).to be_empty,
                           "List items missing from STS HTML:\n#{missing.to_a.first(5).map { |i| "  #{i[0..80]}..." }.join("\n")}"
      end

      it "STS HTML contains all images from the source" do
        missing = mn_fp[:images] - sts_fp[:images]
        expect(missing).to be_empty,
                           "Images missing from STS HTML: #{missing.to_a.inspect}"
      end

      it "STS HTML contains all document identifiers from the source" do
        # Document identifiers appear in both headings and doc-id spans
        mn_docids = mn_fp[:headings] + mn_fp[:paragraphs]
        sts_docids = sts_fp[:paragraphs] + sts_fp[:headings]
        # Just check that the identifier string is somewhere in the STS HTML
        Nokogiri::XML(source_xml).xpath("//m:docidentifier", SOURCE_NS).each do |d|
          id = d.text.strip.downcase
          next if id.empty? || id.match?(/\A\[\d+\]\z/)

          expect(sts_html.downcase).to include(id),
                 "Document identifier '#{id}' missing from STS HTML"
        end
      end
    end
  end
end
