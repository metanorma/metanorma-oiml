# frozen_string_literal: true

# Delegates to the shared engine (metanorma-document 0.5.15, Metanorma::Document::Sts)
# per metanorma-iso#1760 / metanorma-document#165.
#
# Legacy presentation tables (no autonum) split their "Table N — title" name
# into the STS label and caption; ported from metanorma-iso#1890.

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Splits legacy "Table N — title" names into the STS label and caption.
        class TableTransformer < Metanorma::Document::Sts::Transformer::TableTransformer
          # A hyphen or en dash between digits with no spaces ("Table 1-2") marks
          # a range or compound number, so a dash separates only with whitespace
          # on both sides or with a non-digit directly after it.
          LEGACY_DESIGNATION = /
            \A((?i:table)[[:space:]]+(?:[A-Z]\.)?\d+(?:\.\d+)*)
            (?:[[:space:]]+[‒-―−-][[:space:]]+|[[:space:]]*[‒-―−](?!\d))
            (.+)\z
          /mx

          # "Table 2" from the presentation XML autonum attribute; a legacy
          # presentation table with no autonum names itself "Table 2 — …".
          def table_label(source_table)
            return "Table #{source_table.autonum}" if source_table.autonum

            legacy_split(caption_text(source_table)).first
          end

          # Provision-table captions prefer the fully-rendered fmt-name
          # (it carries the "Table N — Requirement M: …" composition);
          # data tables use the semantic <name>.
          def table_caption(source_table)
            text = if source_table.autonum
                     caption_text(source_table)
                   else
                     legacy_split(caption_text(source_table)).last
                   end
            return nil if text.nil? || text.empty?

            ::Sts::NisoSts::Caption.new(
              title: ::Sts::NisoSts::Title.new(content: [text.strip])
            )
          end

          def caption_text(source_table)
            text = nil
            extractor = Metanorma::Document::Sts::Transformer::RenderedTextExtractor
            text = extractor.text_of(source_table.fmt_name) if source_table.fmt_name
            text = extractor.text_of(source_table.name) if (text.nil? || text.empty?) && source_table.name
            text
          end

          def legacy_split(text)
            match = text&.match(LEGACY_DESIGNATION)
            match ? [match[1], match[2]] : [nil, text]
          end
        end
      end
    end
  end
end
