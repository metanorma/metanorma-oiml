# frozen_string_literal: true

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Factory methods for building sts-ruby model instances.
        # Zero Nokogiri — all models are constructed via lutaml-model.
        module ModelBuilder
          module_function

          def standard(lang:, dtd_version: "1.2", front: nil, body: nil, back: nil)
            ::Sts::IsoSts::Standard.new(
              lang: lang,
              dtd_version: dtd_version
            ).tap do |std|
              std.front = front if front
              std.body = body if body
              std.back = back if back
            end
          end

          def front(iso_meta: nil)
            ::Sts::IsoSts::Front.new.tap { |f| f.iso_meta = iso_meta if iso_meta }
          end

          def body(sec: [])
            ::Sts::IsoSts::Body.new(sec: Array(sec))
          end

          def back(app_group: nil, ref_list: [])
            attrs = {}
            attrs[:ref_list] = Array(ref_list) if ref_list&.any?
            ::Sts::IsoSts::Back.new(attrs).tap do |b|
              b.app_group = app_group if app_group
            end
          end

          def app_group(app: [])
            ::Sts::IsoSts::AppGroup.new(app: Array(app))
          end

          def sec(id: nil, label: nil, title: nil, content: [], paragraph: [], sec: [],
                  list: [], table_wrap: [], fig: [], non_normative_note: [],
                  non_normative_example: [])
            all_content = Array(content) + Array(paragraph)
            distributed = distribute_sec_content(all_content)

            attrs = {}
            attrs[:id] = id if id
            attrs[:title] = ::Sts::IsoSts::Title.new(content: [title]) if title
            attrs[:paragraph] = distributed[:paragraph] if distributed[:paragraph].any?
            attrs[:sec] = Array(sec) if sec&.any?
            attrs[:list] = (Array(list) + distributed[:list]) if (list&.any? || distributed[:list].any?)
            attrs[:table_wrap] = (Array(table_wrap) + distributed[:table_wrap]) if (table_wrap&.any? || distributed[:table_wrap].any?)
            attrs[:fig] = (Array(fig) + distributed[:fig]) if (fig&.any? || distributed[:fig].any?)
            attrs[:non_normative_note] = (Array(non_normative_note) + distributed[:note]) if (non_normative_note&.any? || distributed[:note].any?)
            attrs[:non_normative_example] = (Array(non_normative_example) + distributed[:example]) if (non_normative_example&.any? || distributed[:example].any?)
            ::Sts::IsoSts::Sec.new(attrs)
          end

          def distribute_sec_content(content)
            result = Hash.new { |h, k| h[k] = [] }
            content.each do |item|
              case item
              when ::Sts::IsoSts::Paragraph then result[:paragraph] << item
              when ::Sts::IsoSts::List then result[:list] << item
              when ::Sts::IsoSts::Fig then result[:fig] << item
              when ::Sts::TbxIsoTml::TableWrap then result[:table_wrap] << item
              when ::Sts::IsoSts::NonNormativeNote then result[:note] << item
              when ::Sts::IsoSts::NonNormativeExample then result[:example] << item
              when ::Sts::IsoSts::DispFormula then result[:formula] << item
              when ::Sts::IsoSts::DefList then result[:def_list] << item
              end
            end
            result
          end

          def paragraph(id: nil)
            ::Sts::IsoSts::Paragraph.new.tap do |p|
              p.id = id if id
              yield p if block_given?
            end
          end

          def list(list_type: "bullet", list_item: [])
            ::Sts::IsoSts::List.new(list_type: list_type, list_item: Array(list_item))
          end

          def def_list(id: nil, def_items: [])
            items = Array(def_items)
            ::Sts::IsoSts::DefList.new.tap do |dl|
              dl.id = id if id
              dl.def_item = items if items.any?
            end
          end

          def def_item(id: nil, term: nil, defn: nil)
            ::Sts::IsoSts::DefItem.new.tap do |di|
              di.id = id if id
              di.term = term if term
              di.def = defn if defn
            end
          end
          def term(content: [])
            ::Sts::IsoSts::Term.new(content: Array(content))
          end

          def def(paragraph: [])
            ::Sts::IsoSts::Def.new(paragraph: Array(paragraph))
          end

          def list_item(paragraph: [])
            ::Sts::IsoSts::ListItem.new(paragraph: Array(paragraph))
          end

          def table_wrap(id: nil, caption: nil, table: nil)
            ::Sts::TbxIsoTml::TableWrap.new.tap do |tw|
              tw.id = id if id
              tw.caption = caption if caption
              tw.table = [table] if table
            end
          end

          def table(thead: nil, tbody: nil)
            ::Sts::TbxIsoTml::Table.new.tap do |t|
              t.thead = thead if thead
              t.tbody = tbody if tbody
            end
          end

          def thead(tr: [])
            ::Sts::TbxIsoTml::Thead.new(tr: Array(tr))
          end

          def tbody(tr: [])
            ::Sts::TbxIsoTml::Tbody.new(tr: Array(tr))
          end

          def tr(th: [], td: [])
            attrs = {}
            attrs[:th] = Array(th) if th&.any?
            attrs[:td] = Array(td) if td&.any?
            ::Sts::TbxIsoTml::Tr.new(attrs)
          end

          def th(content: nil)
            ::Sts::TbxIsoTml::Th.new.tap { |c| c.content = Array(content) if content }
          end

          def td(content: nil)
            ::Sts::TbxIsoTml::Td.new.tap { |c| c.content = Array(content) if content }
          end

          def fig(id: nil, label: nil, caption: nil, graphic: nil)
            ::Sts::IsoSts::Fig.new.tap do |f|
              f.id = id if id
              f.label = ::Sts::IsoSts::Label.new(content: [label]) if label
              f.caption = caption if caption
              f.graphic = [graphic] if graphic
            end
          end

          def graphic(xlink_href: nil)
            ::Sts::IsoSts::Graphic.new(xlink_href: xlink_href)
          end

          def caption(title: nil)
            ::Sts::IsoSts::Caption.new.tap do |c|
              c.title = ::Sts::IsoSts::Title.new(content: [title]) if title
            end
          end

          def disp_formula(id: nil, label: nil, math: nil)
            ::Sts::IsoSts::DispFormula.new.tap do |f|
              f.id = id if id
              f.label = ::Sts::IsoSts::Label.new(content: [label]) if label
              f.math = math if math
            end
          end

          def inline_formula(math: nil)
            ::Sts::IsoSts::InlineFormula.new(math: math)
          end

          def non_normative_note(paragraph: [], label: nil)
            ::Sts::IsoSts::NonNormativeNote.new.tap do |n|
              n.paragraph = Array(paragraph) if paragraph&.any?
              n.label = ::Sts::IsoSts::Label.new(content: [label]) if label
            end
          end

          def non_normative_example(paragraph: [], label: nil)
            ::Sts::IsoSts::NonNormativeExample.new.tap do |e|
              e.paragraph = Array(paragraph) if paragraph&.any?
              e.label = ::Sts::IsoSts::Label.new(content: [label]) if label
            end
          end

          def ref_list(content_type: nil, title: nil, ref: [])
            ::Sts::IsoSts::RefList.new.tap do |rl|
              rl.content_type = content_type if content_type
              rl.title = ::Sts::IsoSts::Title.new(content: [title]) if title
              rl.ref = Array(ref) if ref&.any?
            end
          end

          def ref(label: nil, mixed_citation: nil, std: nil)
            ::Sts::IsoSts::Ref.new.tap do |r|
              r.label = ::Sts::IsoSts::Label.new(content: [label]) if label
              r.mixed_citation = ::Sts::IsoSts::MixedCitation.new(content: [mixed_citation]) if mixed_citation
              r.std = std if std
            end
          end

          def iso_meta(doc_identifier: nil, title: nil, pub_date: nil,
                       permissions: nil, custom_meta_group: nil)
            ::Sts::IsoSts::IsoMeta.new.tap do |m|
              if title
                m.title_wrap = [::Sts::IsoSts::TitleWrap.new(
                  main: ::Sts::IsoSts::TitleMain.new(content: [title])
                )]
              end
              if doc_identifier
                m.std_ident = std_ident_for(doc_identifier)
              end
              m.permissions = [permissions] if permissions
              if pub_date
                m.pub_date = ::Sts::NisoSts::PubDate.new(
                  date_type: "published", year: pub_date.to_s,
                )
              end
              m.custom_meta_group = custom_meta_group if custom_meta_group
            end
          end

          # <std-ident> per NISO STS (Z39.102-2022): the OIML identifier
          # decomposed into originator + doc-type + doc-number
          # (+ part-number). "OIML B 6-2:2024" → OIML / b / 6 / 2. The
          # publication year is NOT repeated here — pub-date carries it.
          # Identifiers that don't match the OIML pattern fall back to a
          # plain originator string rather than being dropped.
          OIML_ID_PATTERN = /\A(OIML)\s+([A-Z]+)\s+(\d+)(?:-(\d+))?(?::\d{4})?\z/.freeze

          def std_ident_for(doc_identifier)
            match = OIML_ID_PATTERN.match(doc_identifier.to_s.strip)
            return plain_std_ident(doc_identifier) unless match

            attrs = {}
            attrs[:originator] = ::Sts::NisoSts::Originator.new(content: [match[1]])
            attrs[:doc_type] = ::Sts::NisoSts::DocType.new(content: [match[2].downcase])
            attrs[:doc_number] = ::Sts::NisoSts::DocNumber.new(content: [match[3]])
            attrs[:part_number] = ::Sts::NisoSts::PartNumber.new(content: [match[4]]) if match[4]
            ::Sts::IsoSts::StandardIdentification.new(attrs)
          end

          def plain_std_ident(doc_identifier)
            ::Sts::IsoSts::StandardIdentification.new(
              originator: ::Sts::NisoSts::Originator.new(content: [doc_identifier])
            )
          end

          def permissions(holder: nil, year: nil)
            ::Sts::IsoSts::Permissions.new.tap do |p|
              p.copyright_statement = [::Sts::IsoSts::CopyrightStatement.new(content: ["© #{year} #{holder}"])] if year && holder
              p.copyright_year = [::Sts::IsoSts::CopyrightYear.new(content: [year])] if year
              p.copyright_holder = [::Sts::IsoSts::CopyrightHolder.new(content: [holder])] if holder
            end
          end

          def custom_meta_group(name: nil, value: nil)
            ::Sts::NisoSts::CustomMetaGroup.new(
              custom_meta: [::Sts::NisoSts::CustomMeta.new(
                meta_name: name, meta_value: value
              )]
            )
          end

          def bold(content: [])
            ::Sts::IsoSts::Bold.new(content: Array(content))
          end

          def italic(content: [])
            ::Sts::IsoSts::Italic.new(content: Array(content))
          end

          def monospace(content: [])
            ::Sts::IsoSts::Monospace.new(content: Array(content))
          end

          def sub(content: [])
            ::Sts::IsoSts::Sub.new(content: Array(content))
          end

          def sup(content: [])
            ::Sts::IsoSts::Sup.new(content: Array(content))
          end

          def ext_link(xlink_href: nil, content: [])
            ::Sts::IsoSts::ExtLink.new(
              ext_link_type: "uri",
              xlink_href: xlink_href,
              content: Array(content)
            )
          end

          def xref(rid: nil, ref_type: "other", value: nil)
            ::Sts::TbxIsoTml::Xref.new(rid: rid, ref_type: ref_type, value: value)
          end

          def fn(id: nil, value: nil)
            ::Sts::TbxIsoTml::Fn.new(id: id, value: value)
          end

          def title(content: [])
            ::Sts::IsoSts::Title.new(content: Array(content))
          end

          def label(content: [])
            ::Sts::IsoSts::Label.new(content: Array(content))
          end
        end
      end
    end
  end
end
