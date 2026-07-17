# frozen_string: true

require "spec_helper"
require "pathname"

RSpec.describe "OIML multi-document parity" do
  SAMPLES_ROOT = Pathname.new(File.expand_path("~/src/mn/mn-samples-oiml"))
  SITE_ROOT = SAMPLES_ROOT.join("_site/documents")

  def self.sample_documents
    return [] unless SITE_ROOT.exist?

    Dir[SITE_ROOT.join("*/*")].select do |dir|
      next false unless File.directory?(dir)

      pres_xml = File.join(dir, "document.presentation.xml")
      mn_html = File.join(dir, "document.html")
      File.exist?(pres_xml) && File.exist?(mn_html)
    end
  end

  # Skip in CI environments without the sibling repo.
  unless SAMPLES_ROOT.exist?
    warn "skipping multi-document parity: #{SAMPLES_ROOT} not found"
    next
  end

  sample_documents.each do |doc_dir|
    doc_id = doc_dir.sub("#{SITE_ROOT}/", "")

    # Skip collection outputs and amendments — they have non-standard
    # structures (multi-doc wrappers) that aren't representative.
    next if doc_id.include?("collection-output")
    next if doc_id.include?("/amd-")
    next if doc_id.include?("/main")

    context "document #{doc_id}" do
      let(:pres_xml) { File.read(File.join(doc_dir, "document.presentation.xml")) }
      let(:mn_html) { File.read(File.join(doc_dir, "document.html")) }
      let(:sts_xml) { Metanorma::Oiml::Sts.convert(pres_xml) }
      let(:sts_html) do
        Metanorma::Oiml::Sts::HtmlRenderer::Xslt.new.render(sts_xml)
      end
      let(:report) do
        Metanorma::Oiml::Sts::ParityValidator.validate(
          mn_html: mn_html, sts_html: sts_html
        )
      end

      it "converts without raising" do
        expect { sts_xml }.not_to raise_error
      end

      it "renders to HTML without raising" do
        expect { sts_html }.not_to raise_error
      end

      it "achieves at least 75% word coverage" do
        expect(report.word_coverage_percent).to be >= 75.0
      end
    end
  end
end
