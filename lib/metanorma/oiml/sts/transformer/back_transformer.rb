# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        class BackTransformer < Base
          def transform(source)
            app_group = build_app_group(source)
            ref_lists = build_bibliography(source)

            ModelBuilder.back(
              app_group: app_group,
              ref_list: ref_lists
            )
          end

          private

          def build_app_group(source)
            return nil if source.annexes.empty?

            apps = source.annexes.map { |annex| build_app(annex) }
            ModelBuilder.app_group(app: apps)
          end

          # Wrap each annex section in a `<app>` element so it serializes
          # correctly via the sts-ruby AppGroup → App model.
          def build_app(annex)
            sec = section_transformer.transform(annex)
            attrs = {}
            attrs[:id] = sec.id if sec.id
            attrs[:title] = sec.title if sec.title
            attrs[:label] = sec.label if sec.label
            attrs[:paragraph] = sec.paragraph if sec.paragraph&.any?
            attrs[:sec] = sec.sec if sec.sec&.any?
            attrs[:list] = sec.list if sec.list&.any?
            attrs[:table_wrap] = sec.table_wrap if sec.table_wrap&.any?
            attrs[:fig] = sec.fig if sec.fig&.any?
            ::Sts::IsoSts::App.new(attrs)
          end

          def build_bibliography(source)
            return [] if source.bibliography.empty?

            source.bibliography.map { |ref_section| reference_transformer.transform_section(ref_section) }
          end
        end
      end
    end
  end
end
