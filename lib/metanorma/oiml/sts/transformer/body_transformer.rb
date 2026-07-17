# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class BodyTransformer < Base
          def transform(source)
            sections = []

            # Preface sections (foreword, introduction) go at the start of body
            # to avoid the Front model's ordered serialization issue.
            front = FrontTransformer.new(context)
            sections += front.preface_sections(source)

            # Body clauses from <sections>
            sections += source.sections.map do |clause|
              dispatcher.dispatch(clause)
            end.compact

            # Fallback: introduction clauses (OIML PD-style layout)
            if sections.empty? && source.introduction
              sections = dispatcher.dispatch_section_blocks(source.introduction)
                .select { |c| c.is_a?(::Sts::IsoSts::Sec) }
            end

            ModelBuilder.body(sec: sections)
          end
        end
      end
    end
  end
end
