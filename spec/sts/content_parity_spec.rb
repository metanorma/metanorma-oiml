# frozen_string_literal: true

# Per-element content parity tests.
#
# Unlike the aggregate word-retention metric, these tests extract every
# individual semantic element from the source document and verify that
# each one's content appears in the STS output. This catches per-element
# losses that aggregate metrics can hide.
RSpec.describe "OIML STS per-element content parity", :parity do
  include Metanorma::Oiml::Sts::Spec::ContentMatcher

  SOURCE_NS = Metanorma::Oiml::Sts::Spec::ContentMatcher::SOURCE_NS.freeze

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

  def load_fixture(name)
    File.read(FIXTURES_ROOT.join(name))
  end

  def convert_and_parse(name)
    source_xml = load_fixture(name)
    sts_xml = Metanorma::Oiml::Sts.convert(source_xml)
    {
      source_xml: source_xml,
      sts_xml: sts_xml,
      source_doc: parse(source_xml),
      sts_doc: parse(sts_xml)
    }
  end

  FIXTURES.each do |fixture|
    describe fixture do
      let(:ctx) { convert_and_parse(fixture) }
      let(:source_keys) { semantic_keys(ctx[:source_doc]) }
      let(:sts_text) { ctx[:sts_xml] }

      it "preserves every clause title from the source" do
        source_titles = ctx[:source_doc].xpath(
          "//m:clause/m:title", SOURCE_NS
        ).map { |t| t.text.strip }.reject(&:empty?)

        source_titles.each do |title|
          expect(sts_text).to include(title),
                                "Clause title missing from STS: #{title.inspect}"
        end
      end

      it "preserves every paragraph's text content" do
        paragraphs = ctx[:source_doc].xpath(
          "//m:sections//m:p | //m:annex//m:p", SOURCE_NS
        )
        paragraphs.each do |p|
          # Skip paragraphs with fn children — the fn text is emitted
          # separately in STS, so comparing .text directly is misleading.
          next if p.at_xpath("./m:fn", SOURCE_NS)

          text = p.text.strip.gsub(/\s+/, " ")
          next if text.empty? || text.length < 5

          significant_words = text.split.reject { |w| w.length < 3 }.first(5)
          retained = significant_words.select { |w| sts_text.include?(w) }
          expect(retained.size).to be >= (significant_words.size * 0.8).floor,
                                       "Paragraph lost too much text: #{text.inspect}; " \
                                       "missing words: #{significant_words - retained}"
        end
      end

      it "preserves every table cell's text content" do
        require "cgi"
        cells = ctx[:source_doc].xpath(
          "//m:td | //m:th", SOURCE_NS
        )
        cells.each do |cell|
          text = cell.text.strip
          next if text.empty?

          escaped = CGI.escapeHTML(text)
          has_text = sts_text.include?(text) || sts_text.include?(escaped)
          # Also try with common XML entity substitutions
          unless has_text
            # Parse STS as XML and compare text nodes
            sts_doc_parsed = Nokogiri::XML(sts_text)
            sts_texts = sts_doc_parsed.xpath("//td | //th").map(&:text).map(&:strip)
            has_text = sts_texts.include?(text)
          end
          expect(has_text).to be_truthy,
                              "Cell text missing from STS: #{text.inspect}"
        end
      end

      it "preserves every list item's text content" do
        items = ctx[:source_doc].xpath("//m:li", SOURCE_NS)
        items.each do |li|
          # Skip list items that contain nested lists — their raw text
          # concatenates children and isn't a fair comparison.
          next if li.at_xpath("./m:ul | ./m:ol", SOURCE_NS)

          text = li.text.strip
          next if text.empty? || text.length < 3

          words = text.split.reject { |w| w.length < 3 }
          retained = words.select { |w| sts_text.include?(w) }
          expect(retained.size.to_f / [words.size, 1].max).to be >= 0.75,
                                                              "List item lost too much text: #{text.inspect}"
        end
      end

      it "preserves every image @src" do
        srcs = ctx[:source_doc].xpath("//m:image/@src", SOURCE_NS).map(&:value)
        srcs.each do |src|
          expect(sts_text).to include(src),
                              "Image src missing from STS: #{src}"
        end
      end

      it "preserves every docidentifier" do
        docids = ctx[:source_doc].xpath(
          "//m:bibdata/m:docidentifier", SOURCE_NS
        ).map { |d| d.text.strip }
        docids.each do |id|
          next if id.empty?

          expect(sts_text).to include(id),
                              "Doc identifier missing from STS: #{id}"
        end
      end

      it "preserves every bibitem title" do
        titles = ctx[:source_doc].xpath(
          "//m:bibitem/m:title", SOURCE_NS
        ).map { |t| t.text.strip }
        # Parse STS and compare text content (handles entity encoding)
        sts_doc_parsed = Nokogiri::XML(sts_text)
        sts_titles = sts_doc_parsed.xpath("//std/title | //element-citation/title").map(&:text).map(&:strip)
        titles.each do |title|
          next if title.empty?

          expect(sts_titles).to include(title),
                               "Bibitem title missing from STS: #{title.inspect}"
        end
      end
    end
  end
end
