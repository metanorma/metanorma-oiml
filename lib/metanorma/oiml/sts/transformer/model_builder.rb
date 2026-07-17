# frozen_string_literal: true

require "sts"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        module ModelBuilder
          module_function

          def standard(lang:, dtd_version: "1.2", front: nil, body: nil, back: nil)
            attrs = { lang: lang, dtd_version: dtd_version }
            attrs[:front] = front if front
            attrs[:body] = body if body
            attrs[:back] = back if back
            ::Sts::IsoSts::Standard.new(attrs)
          end

          def front(iso_meta: nil, sec: [])
            ::Sts::IsoSts::Front.new(iso_meta: iso_meta, sec: Array(sec))
          end

          def body(sec: [])
            ::Sts::IsoSts::Body.new(sec: Array(sec))
          end

          def back(app_group: nil, ref_list: [])
            attrs = {}
            attrs[:app_group] = app_group if app_group
            attrs[:ref_list] = Array(ref_list) if ref_list&.any?
            ::Sts::IsoSts::Back.new(attrs)
          end

          def app_group(app: [])
            ::Sts::IsoSts::AppGroup.new(app: Array(app))
          end

          def sec(id: nil, label: nil, title: nil, content: [], sec: [])
            attrs = {}
            attrs[:id] = id if id
            attrs[:label] = ::Sts::IsoSts::Label.new(content: [label]) if label
            attrs[:title] = ::Sts::IsoSts::Title.new(content: [title]) if title
            distribute_content(content, attrs)
            attrs[:sec] = Array(sec) if sec&.any?
            ::Sts::IsoSts::Sec.new(attrs)
          end

          def iso_meta(doc_identifier:, title:, pub_date: nil, permissions: nil, custom_meta_group: nil)
            attrs = {}
            attrs[:std_ident] = build_std_ident(doc_identifier) if doc_identifier
            attrs[:title_wrap] = [::Sts::IsoSts::TitleWrap.new(main: ::Sts::IsoSts::TitleMain.new(content: [title]))] if title
            attrs[:pub_date] = ::Sts::NisoSts::PubDate.new(year: pub_date) if pub_date
            attrs[:permissions] = [permissions] if permissions
            attrs[:custom_meta_group] = [custom_meta_group] if custom_meta_group
            ::Sts::IsoSts::IsoMeta.new(attrs)
          end

          def build_std_ident(identifier)
            originator, doc_number = parse_identifier(identifier)
            attrs = {}
            attrs[:originator] = ::Sts::NisoSts::Originator.new(content: [originator]) if originator
            attrs[:doc_number] = ::Sts::NisoSts::DocNumber.new(content: [doc_number]) if doc_number
            ::Sts::IsoSts::StandardIdentification.new(attrs)
          end

          def permissions(holder:, year:)
            ::Sts::IsoSts::Permissions.new(
              copyright_statement: [::Sts::IsoSts::CopyrightStatement.new(content: ["© #{year} #{holder}"])],
              copyright_year: [::Sts::IsoSts::CopyrightYear.new(content: [year])],
              copyright_holder: [::Sts::IsoSts::CopyrightHolder.new(content: [holder])]
            )
          end

          def custom_meta_group(name:, value:)
            ::Sts::NisoSts::CustomMetaGroup.new(
              custom_meta: [::Sts::NisoSts::CustomMeta.new(meta_name: name, meta_value: value)]
            )
          end

          def ref_with_std(org:, identifier:, title:, year: nil)
            std_ref_attrs = {}
            std_ref_attrs[:originator] = ::Sts::NisoSts::Originator.new(content: [org]) if org
            std_ref_attrs[:content] = [identifier] if identifier
            if year
              std_ref_attrs[:year] = ::Sts::NisoSts::Year.new(content: [year])
              std_ref_attrs[:type] = "dated"
            else
              std_ref_attrs[:type] = "undated"
            end
            std_ref = ::Sts::IsoSts::StdRef.new(std_ref_attrs)

            std_attrs = { std_ref: [std_ref] }
            std_attrs[:title] = ::Sts::IsoSts::Title.new(content: [title]) if title
            std = ::Sts::IsoSts::Std.new(std_attrs)

            ::Sts::IsoSts::Ref.new(std: std)
          end

          def ref_with_label_and_std(label:, org:, identifier:, title:, year: nil, content_text: nil)
            std_ref_attrs = {}
            std_ref_attrs[:originator] = ::Sts::NisoSts::Originator.new(content: [org]) if org
            std_ref_attrs[:content] = [identifier] if identifier
            if year
              std_ref_attrs[:year] = ::Sts::NisoSts::Year.new(content: [year])
              std_ref_attrs[:type] = "dated"
            else
              std_ref_attrs[:type] = "undated"
            end
            std_ref = ::Sts::IsoSts::StdRef.new(std_ref_attrs)

            std_attrs = { std_ref: [std_ref] }
            std_attrs[:title] = ::Sts::IsoSts::Title.new(content: [title]) if title
            std = ::Sts::IsoSts::Std.new(std_attrs)

            ref_attrs = { std: std }
            if label
              ref_attrs[:label] = ::Sts::IsoSts::Label.new(content: [label])
            end
            if content_text
              ref_attrs[:mixed_citation] = ::Sts::IsoSts::MixedCitation.new(content: [content_text])
            end
            ::Sts::IsoSts::Ref.new(ref_attrs)
          end

          def ref_list(content_type: "bibliography", refs: [], title: nil)
            attrs = { content_type: content_type, ref: Array(refs) }
            attrs[:title] = title if title
            ::Sts::IsoSts::RefList.new(attrs)
          end

          def distribute_content(content, attrs)
            content.each do |item|
              case item
              when ::Sts::IsoSts::Sec
                (attrs[:sec] ||= []) << item
              when ::Sts::IsoSts::Paragraph
                (attrs[:paragraph] ||= []) << item
              when ::Sts::IsoSts::List
                (attrs[:list] ||= []) << item
              when ::Sts::IsoSts::DefList
                (attrs[:def_list] ||= []) << item
              when ::Sts::TbxIsoTml::TableWrap
                (attrs[:table_wrap] ||= []) << item
              when ::Sts::IsoSts::Fig
                (attrs[:fig] ||= []) << item
              when ::Sts::IsoSts::NonNormativeNote
                (attrs[:non_normative_note] ||= []) << item
              when ::Sts::IsoSts::NonNormativeExample
                (attrs[:non_normative_example] ||= []) << item
              when ::Sts::IsoSts::DispFormula
                (attrs[:disp_formula] ||= []) << item
              when ::Sts::NisoSts::DispQuote
                (attrs[:disp_quote] ||= []) << item
              when ::Sts::IsoSts::Preformat
                (attrs[:preformat] ||= []) << item
              end
            end
          end

          def parse_identifier(identifier)
            return [nil, nil] unless identifier
            if (m = identifier.match(/\AOIML\s+([A-Z])\s*(\d+)/))
              ["OIML #{m[1]}", m[2]]
            elsif (m = identifier.match(/\A(ISO|IEC)\s+(\d+)/))
              [m[1], m[2]]
            else
              [identifier, nil]
            end
          end
        end
      end
    end
  end
end
