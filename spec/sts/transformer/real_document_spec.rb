# frozen_string_literal: true

# Presentation XML compiled from a real OIML AsciiDoc source (term with a
# note and an example; table with a footnote). Guards the paths that the
# hand-written sample.xml never reaches (metanorma-oiml#46).
RSpec.describe "OIML STS conversion of a compiled document" do
  let(:input) { File.read(FIXTURES_ROOT.join("term_note_table_fn.presentation.xml")) }
  let(:output) { Metanorma::Oiml::Sts.convert(input) }

  it "converts without raising" do
    expect { output }.not_to raise_error
  end

  it "keeps a term note with its label" do
    expect(output).to match(%r{<non-normative-note>\s*<p[^>]*>A first term note\.</p>\s*<label>Note:</label>})
  end

  it "prefixes the first paragraph of a term example with its label" do
    expect(output).to match(%r{<p[^>]*>Example: A term example\.</p>})
  end

  it "keeps the table footnote body inside the cell" do
    expect(output).to match(%r{<fn [^>]*><label>a</label><p>a First table note\.</p></fn>})
  end

  it "validates against the OIML rules" do
    expect(Metanorma::Oiml::Sts.validate(output).errors).to be_empty
  end
end
