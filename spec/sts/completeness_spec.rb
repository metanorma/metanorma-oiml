# frozen_string_literal: true

require "set"

# Content completeness tests: verify that the STS output preserves ALL
# semantic information from the Metanorma presentation XML input.
#
# The presentation XML contains rendering duplicates (fmt-*, semx, asciimath,
# localized-string, etc.). The ContentMatcher helper strips those before
# comparing, so these tests measure true semantic content preservation.
RSpec.describe "OIML STS content completeness", :content do
  include Metanorma::Oiml::Sts::Spec::ContentMatcher

  def load_fixture(name)
    File.read(FIXTURES_ROOT.join(name))
  end

  def convert_fixture(name)
    Metanorma::Oiml::Sts.convert(load_fixture(name))
  end

  describe "minimal document (sample.xml)" do
    let(:source) { load_fixture("sample.xml") }
    let(:sts) { convert_fixture("sample.xml") }

    it "preserves the document identifier" do
      expect(sts).to include("<originator>OIML R</originator>")
    end

    it "preserves the title" do
      expect(sts).to include("<main>Clinical thermometers")
    end

    it "preserves section titles" do
      expect(sts).to include("<title>Scope</title>")
    end

    it "preserves all semantic words from the source" do
      expect(word_retention(source)).to be >= 0.90
    end

    it "preserves paragraph text" do
      expect(sts).to include("This Recommendation applies to clinical thermometers.")
    end

    it "preserves list items" do
      expect(sts).to include("First bullet.")
      expect(sts).to include("Second bullet.")
    end
  end

  describe "complete metadata" do
    let(:sts) { convert_fixture("complete_metadata.xml") }

    it "preserves the OIML identifier with year" do
      expect(sts).to include("<originator>OIML R</originator>")
    end

    it "preserves the title" do
      expect(sts).to include("Metrological regulation for load cells")
    end

    it "records the OIML series letter" do
      expect(sts).to include("<meta-name>oiml-doc-series</meta-name>")
      expect(sts).to include("<meta-value>R</meta-value>")
    end

    it "preserves publication year" do
      expect(sts).to include("<year>2000</year>")
    end

    it "preserves copyright holder" do
      expect(sts).to include("<copyright-holder>International Organization of Legal Metrology</copyright-holder>")
    end

    it "preserves the publisher contributor" do
      expect(sts).to include("<copyright-holder>International Organization of Legal Metrology</copyright-holder>")
    end

    it "preserves the scope paragraph" do
      expect(sts).to include("This Recommendation applies to load cells")
    end
  end

  describe "nested sections" do
    let(:sts) { convert_fixture("nested_sections.xml") }

    it "emits all top-level and nested sections as <sec>" do
      doc = Nokogiri::XML(sts)
      sections = doc.xpath("//sec")
      expect(sections.size).to eq(5)
    end

    it "preserves section nesting depth" do
      doc = Nokogiri::XML(sts)
      # Top-level sec with children: s_top > s_top_a > s_top_a_1
      top = doc.at_xpath("//body/sec[title='Top-level clause']")
      expect(top).not_to be_nil
      expect(top.xpath("./sec").size).to eq(2)
      sub_a = top.at_xpath("./sec[title='First sub-clause']")
      expect(sub_a).not_to be_nil
      expect(sub_a.at_xpath("./sec/title").text).to eq("Sub-sub-clause")
    end

    it "preserves all section titles" do
      titles = Nokogiri::XML(sts).xpath("//sec/title").map(&:text)
      expect(titles).to include("Top-level clause", "First sub-clause",
                                "Second sub-clause", "Sub-sub-clause",
                                "Another top clause")
    end

    it "preserves deeply nested paragraph text" do
      expect(sts).to include("Deeply nested content.")
    end

    it "preserves all words" do
      expect(word_retention(load_fixture("nested_sections.xml"))).to be >= 0.85
    end
  end

  describe "inline markup" do
    let(:sts) { convert_fixture("inline_markup.xml") }

    it "converts <em> to <italic>" do
      expect(sts).to include("<italic>italic text</italic>")
    end

    it "converts <strong> to <bold>" do
      expect(sts).to include("<bold>bold text</bold>")
    end

    it "converts <tt> to <monospace>" do
      expect(sts).to include("<monospace>code sample</monospace>")
    end

    it "converts <sub> and <sup>" do
      expect(sts).to include("<sub>subscript</sub>")
      expect(sts).to include("<sup>superscript</sup>")
    end

    it "converts <xref> to <xref ref-type='sec'>" do
      expect(sts).to include('<xref rid="s_inline" ref-type="sec">')
      expect(sts).to include("clause 1")
    end

    it "converts <link> to <ext-link xlink:href>" do
      expect(sts).to include("<ext-link")
      expect(sts).to include('xlink:href="https://www.oiml.org"')
      expect(sts).to include("OIML website")
    end

    it "converts <fn> to an STS <fn> element with footnote text" do
      expect(sts).to include("<fn")
      expect(sts).to include("Footnote text content.")
    end

    it "handles nested inline markup (em containing strong)" do
      expect(sts).to include("<italic>italic and <bold>bold</bold> together</italic>")
    end

    it "preserves all words including inline content" do
      expect(word_retention(load_fixture("inline_markup.xml"))).to be >= 0.90
    end
  end

  describe "lists" do
    let(:sts) { convert_fixture("lists.xml") }

    it "converts <ul> to <list list-type='bullet'>" do
      expect(sts).to match(%r{<list[^>]*list-type="bullet"})
    end

    it "converts <ol> to <list list-type='order'>" do
      expect(sts).to match(%r{<list[^>]*list-type="order"})
    end

    it "converts <li> to <list-item>" do
      doc = Nokogiri::XML(sts)
      expect(doc.xpath("//list-item").size).to be >= 8
    end

    it "preserves nested list structure" do
      doc = Nokogiri::XML(sts)
      # Nested list appears inside a <list-item>
      nested = doc.xpath("//list-item/list").size
      expect(nested).to be >= 1
    end

    it "preserves all list item text" do
      %w[First Second Third Outer Inner].each do |word|
        expect(sts).to include(word)
      end
    end

    it "preserves all words" do
      expect(word_retention(load_fixture("lists.xml"))).to be >= 0.90
    end
  end

  describe "tables" do
    let(:sts) { convert_fixture("tables.xml") }

    it "wraps every source table in <table-wrap>" do
      expect(Nokogiri::XML(sts).xpath("//table-wrap").size).to eq(2)
    end

    it "emits the header row from <thead>" do
      expect(sts).to include("<th>Class</th>")
      expect(sts).to include("<th>Range</th>")
      expect(sts).to include("<th>Accuracy</th>")
    end

    it "emits all body rows from <tbody>" do
      doc = Nokogiri::XML(sts)
      first_table = doc.at_xpath("//table-wrap/table")
      rows = first_table.xpath("./tr")
      expect(rows.size).to eq(4)
    end

    it "preserves cell text content" do
      doc = Nokogiri::XML(sts)
      cells = doc.xpath("//td").map(&:text)
      expect(cells).to include("±0.1%")
      expect(cells).to include("±0.5%")
      expect(cells).to include("0–500 kg")
    end

    it "preserves inline markup inside cells" do
      expect(sts).to include("<italic>italic</italic>")
      expect(sts).to include("<bold>bold</bold>")
    end

    it "preserves all words" do
      expect(word_retention(load_fixture("tables.xml"))).to be >= 0.85
    end
  end

  describe "figures" do
    let(:sts) { convert_fixture("figures.xml") }

    it "wraps each source figure in <fig>" do
      expect(Nokogiri::XML(sts).xpath("//fig").size).to eq(2)
    end

    it "emits <graphic> for each <image>" do
      expect(sts).to include('xlink:href="figures/diagram.png"')
      expect(sts).to include('xlink:href="figures/graph.jpg"')
    end

    it "preserves figure captions" do
      expect(sts).to include("Schematic diagram")
      expect(sts).to include("Measurement results")
    end
  end

  describe "formulae" do
    let(:sts) { convert_fixture("formulae.xml") }

    it "converts <formula> to <disp-formula>" do
      expect(sts).to include("<disp-formula")
    end

    it "preserves MathML content" do
      expect(sts).to include("<math")
      expect(sts).to include("<mi>E</mi>")
      expect(sts).to include("<mi>m</mi>")
    end

    it "does not leak asciimath text" do
      # asciimath fallback should be skipped, not dumped as text
      expect(sts).not_to include("asciimath")
      expect(sts).not_to include("E = m xx g")
    end

    it "converts inline <stem> to <inline-formula>" do
      expect(sts).to include("<inline-formula")
      expect(sts).to include("<mi>v</mi>")
    end
  end

  describe "notes and examples" do
    let(:sts) { convert_fixture("notes_examples.xml") }

    it "converts <note> to <non-normative-note>" do
      expect(sts).to include("<non-normative-note")
      expect(sts).to include("This is a normative note.")
    end

    it "converts <example> to <non-normative-example>" do
      expect(sts).to include("<non-normative-example")
      expect(sts).to include("This is an example.")
    end

    it "preserves inline markup inside notes" do
      expect(sts).to include("<italic>inline markup</italic>")
    end
  end

  describe "bibliography" do
    let(:sts) { convert_fixture("bibliography.xml") }

    it "emits <ref-list> for the bibliography" do
      expect(sts).to include("<ref-list")
      expect(sts).to include('content-type="bibliography"')
    end

    it "converts standards bibitems to <std> with <title> and <pub-date>" do
      expect(sts).to include("<std>")
      expect(sts).to include("ISO 9001:2015")
      expect(sts).to include("<title>Quality management systems")
      expect(sts).to include("<year>2015</year>")
    end

    it "preserves OIML bibitems" do
      expect(sts).to include("OIML R 76:2006")
      expect(sts).to include("<title>Non-automatic weighing instruments")
    end

    it "uses the actual identifier, not the ordinal" do
      expect(sts).not_to include("<doc-identifier>[1]</doc-identifier>")
    end
  end

  describe "annexes" do
    let(:sts) { convert_fixture("annexes.xml") }

    it "wraps annexes in <app-group> with <app> entries" do
      expect(sts).to include("<app-group")
      doc = Nokogiri::XML(sts)
      expect(doc.xpath("//app").size).to eq(2)
    end

    it "preserves annex titles" do
      expect(sts).to include("Normative annex")
      expect(sts).to include("Informative annex")
    end

    it "preserves annex content" do
      expect(sts).to include("This annex is normative.")
      expect(sts).to include("This annex is informative.")
    end
  end
end
