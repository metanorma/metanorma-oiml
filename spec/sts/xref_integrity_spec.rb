# frozen_string_literal: true

# Cross-reference integrity tests.
#
# Verify that every `<xref>` in the source resolves to a real target in
# the STS output, and that the STS output doesn't have dangling @rid
# references.
RSpec.describe "OIML STS cross-reference integrity", :xref do
  include Metanorma::Oiml::Sts::Spec::ContentMatcher

  SOURCE_NS = Metanorma::Oiml::Sts::Spec::ContentMatcher::SOURCE_NS.freeze

  FIXTURES = %w[
    sample.xml
    nested_sections.xml
    inline_markup.xml
    tables.xml
    bibliography.xml
    annexes.xml
  ].freeze

  def load_fixture(name)
    File.read(FIXTURES_ROOT.join(name))
  end

  FIXTURES.each do |fixture|
    describe fixture do
      let(:source_doc) { parse(load_fixture(fixture)) }
      let(:sts_xml) { Metanorma::Oiml::Sts.convert(load_fixture(fixture)) }
      let(:sts_doc) { parse(sts_xml) }

      it "preserves every source xref target as an @rid in STS" do
        source_targets = source_xref_targets(source_doc)
        sts_rids = sts_xref_rids(sts_doc)

        missing = source_targets - sts_rids
        expect(missing).to be_empty,
                           "Source xref targets missing from STS @rid set: #{missing.inspect}"
      end

      it "STS xref @rid values point to existing @id targets in STS" do
        sts_rids = sts_doc.xpath("//xref/@rid").map(&:value).uniq
        sts_ids = all_ids(sts_doc)

        dangling = sts_rids - sts_ids
        # Some rids may point to footnotes that are registered in the
        # FootnoteCollector (e.g. "fn_1"). Those ARE in the output as
        # <fn id="fn_1">, so they should resolve.
        expect(dangling).to be_empty,
                            "Dangling STS xref @rid values: #{dangling.inspect}"
      end
    end
  end

  describe "specific cross-reference scenarios" do
    it "converts <xref type='clause'> to <xref ref-type='sec'>" do
      sts = Metanorma::Oiml::Sts.convert(File.read(FIXTURES_ROOT.join("inline_markup.xml")))
      expect(sts).to include('<xref rid="s_inline" ref-type="sec">')
    end

    it "converts <xref type='table'> to <xref ref-type='table'>" do
      source = <<~XML
        <?xml version="1.0"?>
        <metanorma xmlns="https://www.metanorma.org/ns/standoc">
        <bibdata type="standard"><docidentifier primary="true">OIML R 1</docidentifier><language>en</language><contributor><role type="publisher"/><organization><name>OIML</name></organization></contributor><copyright><from>2024</from><owner><organization><name>OIML</name></organization></owner></copyright><status><stage>60</stage></status></bibdata>
        <sections>
        <clause id="s1" obligation="normative"><title>Ref test</title>
        <table id="tbl_x"><tbody><tr><td>A</td></tr></tbody></table>
        <p>See <xref target="tbl_x" type="table">Table X</xref>.</p>
        </clause>
        </sections>
        </metanorma>
      XML
      sts = Metanorma::Oiml::Sts.convert(source)
      expect(sts).to include('<xref rid="tbl_x" ref-type="table">')
      expect(sts).to include("Table X")
    end

    it "converts <xref type='figure'> to <xref ref-type='fig'>" do
      source = <<~XML
        <?xml version="1.0"?>
        <metanorma xmlns="https://www.metanorma.org/ns/standoc">
        <bibdata type="standard"><docidentifier primary="true">OIML R 1</docidentifier><language>en</language><contributor><role type="publisher"/><organization><name>OIML</name></organization></contributor><copyright><from>2024</from><owner><organization><name>OIML</name></organization></owner></copyright><status><stage>60</stage></status></bibdata>
        <sections>
        <clause id="s1" obligation="normative"><title>Ref test</title>
        <figure id="fig_x"><image src="x.png"/><name>Figure X</name></figure>
        <p>See <xref target="fig_x" type="figure">Figure X</xref>.</p>
        </clause>
        </sections>
        </metanorma>
      XML
      sts = Metanorma::Oiml::Sts.convert(source)
      expect(sts).to include('<xref rid="fig_x" ref-type="fig">')
    end
  end
end
