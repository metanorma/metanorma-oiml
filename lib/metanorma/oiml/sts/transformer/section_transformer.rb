# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class SectionTransformer < Metanorma::Document::Sts::Transformer::SectionTransformer
          # OIML terms are ordinary <sec> entries (not TBX <term-sec>), so a
          # nested terms section wraps its terms as nested <sec>.
          def transform_terms_section(terms_section)
            title_text = extract_title(terms_section)
            autonum = extract_autonum(terms_section)
            terms_id = id_generator.id_for_terms(terms_section, autonum)

            nested = Array(terms_section.term).filter_map { |term| term_transformer.transform(term) }
            return nil unless title_text || autonum || nested.any?

            ::Sts::NisoSts::Section.new do |sec|
              sec.id = terms_id if terms_id
              sec.type = "terms"
              sec.label = ::Sts::NisoSts::Label.new(content: [autonum]) if autonum
              sec.title = ::Sts::NisoSts::Title.new(content: [title_text]) if title_text && !title_text.empty?
              nested.each { |ts| sec.sec ts }
            end
          end
        end
      end
    end
  end
end
