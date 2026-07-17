# frozen_string: true
module Metanorma::Oiml::Sts::Source
  class BibliographicItem < Base
    def identifier
      ids = Array(typed.docidentifier)
      return nil if ids.empty?
      primary = ids.find { |i| i.type.nil? } || ids.first
      InlineExtractor.text_from(primary)
    end

    def formattedref_text
      fr = typed.formatted_ref
      return nil unless fr
      text_parts = []
      fr.each_mixed_content do |n|
        text_parts << (n.is_a?(String) ? n : InlineExtractor.text_from(n))
      end
      text = text_parts.join.strip
      text.empty? ? nil : text
    end

    def year
      dates = Array(typed.date)
      return nil if dates.empty?
      pub = dates.find { |d| d.type == "published" } || dates.first
      return nil unless pub
      on = pub.on
      return nil unless on
      val = on.content || on.id || on.value
      val.to_s[/\d{4}/]
    end
  end
end
Metanorma::Oiml::Sts::Source::Registry.register(
  Metanorma::Document::Components::BibData::BibliographicItem,
  Metanorma::Oiml::Sts::Source::BibliographicItem
)
