# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Transforms a Metanorma `<bibitem>` into a NISO STS `<ref>` wrapping
        # `<element-citation>`. For standards references, emits `<std>` with
        # the required `<title>` and `<pub-date>` (per OIML X 999 Clause 6).
        class ReferenceTransformer < Base
          def transform(source_node, builder)
            builder.ref do
              builder.element_citation do
                emit_std(source_node, builder) || emit_generic(source_node, builder)
              end
            end
          end

          private

          def emit_std(source_node, builder)
            return false unless standard_reference?(source_node)

            builder.std do
              emit_std_ident(source_node, builder)
              emit_title(source_node, builder)
              emit_pub_date(source_node, builder)
            end
            true
          end

          def emit_generic(source_node, builder)
            title = source_node.at_xpath("./m:title", source.namespaces)&.text&.strip
            builder.text(title) if title
          end

          def standard_reference?(source_node)
            !!source_node.at_xpath(".//m:docidentifier", source.namespaces)
          end

          def emit_std_ident(source_node, builder)
            identifier = source_node.at_xpath("./m:docidentifier", source.namespaces)&.text&.strip
            return unless identifier

            builder.std_ident do
              builder.std_org(publisher_org(identifier))
              builder.doc_identifier(identifier)
            end
          end

          def emit_title(source_node, builder)
            title = source_node.at_xpath("./m:title", source.namespaces)&.text&.strip
            builder.title(title) if title
          end

          def emit_pub_date(source_node, builder)
            year = source_node.at_xpath("./m:date[@type='published']/m:on | ./m:date/m:on", source.namespaces)&.text&.strip
            return unless year

            builder.pub_date { builder.year(year) }
          end

          def publisher_org(identifier)
            case identifier
            when /\AOIML\b/ then "OIML"
            when /\AISO\b/  then "ISO"
            when /\AIEC\b/  then "IEC"
            when /\AANSI\/NISO\b/ then "NISO"
            else "ISO"
            end
          end
        end
      end
    end
  end
end
