# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Term < Base
    def preferred_name
      pref = Array(typed.preferred).first
      return nil unless pref
      expr = pref.expression
      return nil unless expr
      names = Array(expr.name)
      return nil if names.empty?
      InlineExtractor.text_from(names.first)
    end

    def definition_text
      defn = Array(typed.definition).first
      return nil unless defn
      vd = defn.verbal_definition
      return nil unless vd
      ps = Array(vd.p)
      return nil if ps.empty?
      InlineExtractor.text_from(ps.first)
    end

    def paragraphs; Array(typed.p); end
    def unordered_lists; Array(typed.ul); end
    def ordered_lists; Array(typed.ol); end
    def termnotes; Array(typed.termnote); end
    def termexamples; Array(typed.termexample); end
    def notes; Array(typed.note); end
    def sources; Array(typed.source); end
    def nested_terms; Array(typed.term); end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::IsoDocument::Terms::IsoTerm,
  Metanorma::Oiml::Sts::Source::Term
)
