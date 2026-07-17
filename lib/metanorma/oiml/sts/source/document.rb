# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class Document < Base
    def bibdata; typed.bibdata; end
    def preface; typed.preface; end
    def foreword; typed.preface ? typed.preface.foreword : nil; end
    def introduction; typed.preface ? typed.preface.introduction : nil; end
    def sections; typed.sections; end
    def clauses; Array(typed.sections.clause); end
    def annexes; Array(typed.annex); end
    def bibliography; typed.bibliography; end
    def boilerplate; typed.boilerplate; end

    def language
      return "en" unless bibdata
      langs = bibdata.language
      return "en" unless langs
      lang = langs.is_a?(Array) ? langs.first : langs
      val = lang.respond_to?(:value) ? lang.value : lang.to_s
      val.to_s.strip.match?(/\A[a-z]{2}(-[A-Z]{2})?\z/) ? val.to_s.strip : "en"
    end

    def docidentifier
      return nil unless bibdata
      ids = bibdata.doc_identifier
      return nil unless ids
      Array(ids).each do |id_obj|
        next if id_obj.type
        return InlineExtractor.text_from(id_obj)
      end
      InlineExtractor.text_from(Array(ids).first)
    end

    def title(type: nil)
      return nil unless bibdata
      titles = bibdata.titles || bibdata.title
      return nil unless titles
      titles = Array(titles)
      t = titles.find { |x| type.nil? || (x.type == type) } || titles.first
      InlineExtractor.text_from(t)
    end

    def copyright_year
      return nil unless bibdata
      cps = bibdata.copyright
      return nil unless cps
      cp = Array(cps).first
      return nil unless cp
      from = cp.from
      return nil unless from
      InlineExtractor.text_from(from)
    end

    def copyright_holder
      return nil unless bibdata
      cps = bibdata.copyright
      return nil unless cps
      cp = Array(cps).first
      return nil unless cp
      owner = cp.owner
      return nil unless owner
      org = Array(owner.organization).first
      return nil unless org
      name = org.name
      InlineExtractor.text_from(name)
    end
  end
end
