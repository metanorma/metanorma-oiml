# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Builds a `Sts::IsoSts::Front` containing ONLY `<iso-meta>`.
        # Foreword and introduction sections are emitted by BodyTransformer
        # to avoid the Front model's `ordered` serialization issue when
        # multiple collection attributes are set simultaneously.
        class FrontTransformer < Base
          def transform(source)
            ModelBuilder.front(iso_meta: build_iso_meta(source))
          end

          # Returns foreword/introduction sections for the body.
          def preface_sections(source)
            sections = []
            sections += build_boilerplate(source) if source.respond_to?(:typed_root)
            sections += build_foreword(source) if source.foreword
            sections += build_introduction(source) if source.introduction
            sections
          end

          private

          def build_boilerplate(source)
            typed = source.typed_root
            bp = typed.boilerplate
            return [] unless bp

            sections = []
            sections += build_boilerplate_section(bp.copyright_statement, "Copyright")
            sections += build_boilerplate_section(bp.feedback_statement, "Feedback")
            sections
          end

          def build_boilerplate_section(stmt_collection, default_title)
            sections = []
            Array(stmt_collection).each do |cs|
              cs.each_mixed_content do |inner|
                next if inner.is_a?(String)
                next unless inner.respond_to?(:paragraphs)

                paragraphs = Array(inner.paragraphs).map { |p| paragraph_transformer.transform(p) }
                next if paragraphs.empty?

                sections << ModelBuilder.sec(title: default_title, content: paragraphs)
              end
            end
            sections
          end

          def build_iso_meta(source)
            return nil unless source.has_metadata?

            ModelBuilder.iso_meta(
              doc_identifier: source.docidentifier,
              title: source.formatted_title || source.title(type: "main") || source.title,
              pub_date: source.pub_date,
              permissions: build_permissions(source),
              custom_meta_group: build_custom_meta(source)
            )
          end

          def build_permissions(source)
            holder = source.copyright_holder || source.publisher || "OIML"
            year = source.copyright_year || source.pub_date || Time.now.year.to_s
            ModelBuilder.permissions(holder: holder, year: year)
          end

          def build_custom_meta(source)
            series = oiml_series_letter(source.docidentifier)
            return nil unless series

            ModelBuilder.custom_meta_group(name: "oiml-doc-series", value: series)
          end

          def build_foreword(source)
            content = dispatcher.dispatch_section_blocks(source.foreword)
            [ModelBuilder.sec(label: nil, title: "Foreword", content: content)]
          end

          def build_introduction(source)
            content = dispatcher.dispatch_section_blocks(source.introduction)
            [ModelBuilder.sec(label: nil, title: "Introduction", content: content)]
          end

          def oiml_series_letter(identifier)
            return nil unless identifier

            identifier.match(/\AOIML\s+([A-Z])\s/) { |m| m[1] }
          end
        end
      end
    end
  end
end
