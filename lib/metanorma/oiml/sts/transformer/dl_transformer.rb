# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Converts MN `<dl>`/`<dt>`/`<dd>` to STS `<def-list>`/`<def-item>`.
        # Follows mnconvert's pattern (mn2xml.xsl lines 5327-5528): each
        # dt/dd pair becomes a def-item with term + def children. Notes
        # inside dl are extracted as siblings after the def-list.
        class DlTransformer < Metanorma::Document::Sts::Transformer::DlTransformer
          def transform(source_dl)
            def_items = pair_dt_dd(source_dl)
            Metanorma::Document::Sts::Transformer::ModelBuilder.def_list(id: source_dl.id, def_items: def_items)
          end

          private

          def pair_dt_dd(source_dl)
            dts = Array(source_dl.dt)
            dds = Array(source_dl.dd)
            dts.each_with_index.map do |dt, i|
              build_def_item(dt, dds[i])
            end
          end

          def build_def_item(dt, dd)
            attrs = {}
            attrs[:id] = dt.id if dt.class.method_defined?(:id) && dt.id

            term_text = Metanorma::Document::Sts::Transformer::RenderedTextExtractor.text_of(dt)
            term = term_text.nil? || term_text.empty? ? nil : Metanorma::Document::Sts::Transformer::ModelBuilder.term(content: [term_text])

            defn = dd ? build_def(dd) : nil

            attrs[:term] = term if term
            attrs[:defn] = defn if defn
            Metanorma::Document::Sts::Transformer::ModelBuilder.def_item(**attrs)
          end

          def build_def(dd)
            paragraphs = Array(dd.p).map { |p| paragraph_transformer.transform(p) }
            Metanorma::Document::Sts::Transformer::ModelBuilder.def(paragraph: paragraphs)
          end
        end
      end
    end
  end
end
