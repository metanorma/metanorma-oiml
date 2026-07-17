# frozen_string_literal: true

module Metanorma::Oiml::Sts::Source
  # Single source of truth for extracting plain text from any source
  # object (String, Array, typed model, or adapter).
  class InlineExtractor
    class << self
      def text_from(obj)
        case obj
        when nil then ""
        when String then obj
        when Array then obj.map { |v| text_from(v) }.join
        when Base then obj.text
        else extract_from_typed(obj)
        end
      end

      private

      def extract_from_typed(obj)
        text = try_attribute(obj, :text)
        return text if text && !text.empty?

        content = try_attribute(obj, :content)
        return content if content && !content.empty?

        ""
      end

      def try_attribute(obj, name)
        return nil unless obj.respond_to?(name)

        val = obj.public_send(name)
        return nil if val.nil?

        val = Array(val).map(&:to_s).join.strip if val.is_a?(Array)
        val.to_s.strip
      end
    end
  end
end
