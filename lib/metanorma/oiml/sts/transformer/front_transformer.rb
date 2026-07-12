# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Emits the `<front>` block: `<iso-meta>`, foreword, introduction.
        class FrontTransformer < Base
          def transform(source, builder)
            emit_iso_meta(source, builder) if source.has_metadata?
            emit_foreword(source, builder) if source.foreword
            emit_introduction(source, builder) if source.introduction
          end

          private

          def emit_iso_meta(source, builder)
            builder.iso_meta("xml:lang" => context.language) do
              builder.doc_identifier(source.docidentifier) if source.docidentifier
              emit_title_group(source, builder)
              emit_pub_date(source, builder)
              emit_release_version(source, builder)
              emit_permissions(source, builder)
              emit_contributors(source, builder)
              emit_custom_meta(source, builder)
            end
          end

          def emit_title_group(source, builder)
            title = source.title(type: "main") || source.title
            return unless title

            builder.std_title_group { builder.title(title) }
          end

          def emit_pub_date(source, builder)
            date = source.pub_date
            return unless date

            builder.pub_date("date-type" => "published") do
              builder.year(date)
            end
          end

          def emit_release_version(source, builder)
            stage = source.stage_code || "60"
            label = release_label(stage)
            builder.release_version("stage-code" => stage) { builder.text(label) }
          end

          def emit_permissions(source, builder)
            holder = source.copyright_holder || source.publisher || "OIML"
            year = source.copyright_year || source.pub_date || Time.now.year
            builder.permissions do
              builder.copyright_statement("#{copyright_symbol} #{year} #{holder}")
              builder.copyright_year(year)
              builder.copyright_holder(holder)
            end
          end

          def emit_contributors(source, builder)
            publisher = source.publisher
            return unless publisher

            builder.contrib_group do
              builder.contrib do
                builder.role("type" => "publisher")
                builder.organization { builder.name(publisher) }
              end
            end
          end

          def emit_custom_meta(source, builder)
            series = oiml_series_letter(source.docidentifier)
            return unless series

            builder.custom_meta_group do
              builder.custom_meta do
                builder.meta_name("oiml-doc-series")
                builder.meta_value(series)
              end
            end
          end

          def emit_foreword(source, builder)
            builder.foreword do
              inline_transformer.transform_children(source.foreword, builder)
            end
          end

          def emit_introduction(source, builder)
            builder.introduction do
              inline_transformer.transform_children(source.introduction, builder)
            end
          end

          def release_label(stage)
            case stage.to_s
            when "30" then "Working draft"
            when "40" then "Committee draft"
            when "50" then "Draft"
            when "60" then "Published"
            else "Published"
            end
          end

          def oiml_series_letter(identifier)
            return nil unless identifier

            match = identifier.match(/\AOIML\s+([A-Z])\s/)
            match ? match[1] : nil
          end

          def copyright_symbol
            "©"
          end
        end
      end
    end
  end
end
