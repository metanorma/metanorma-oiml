# frozen_string_literal: true

require "nokogiri"

module Metanorma
  module Oiml
    module Sts
      module Transformer
        # Thin wrapper around Nokogiri::XML::Document for emitting OIML NISO
        # STS XML. Every transformer emits through {StsXml}; no transformer
        # calls Nokogiri directly in emission code.
        class StsXml
          XHTML_NS = "http://www.w3.org/1999/xhtml".freeze
          XLINK_NS = "http://www.w3.org/1999/xlink".freeze
          MML_NS = "http://www.w3.org/1998/Math/MathML".freeze

          attr_reader :document

          def initialize
            @document = Nokogiri::XML::Document.new
            @stack = []
          end

          def to_xml
            document.to_xml(indent: 2)
          end

          def method_missing(name, *args, **kwargs, &block)
            return super unless respond_to_missing?(name)

            attrs = kwargs.transform_keys { |k| k.to_s.tr("_", "-") }
            emit(name.to_s.tr("_", "-"), args.first, attrs, &block)
          end

          def respond_to_missing?(name, _include_private = false)
            name.to_s.match?(/\A[a-zA-Z][a-zA-Z0-9_:_-]*\z/)
          end

          def text(content)
            return if content.nil?

            current << Nokogiri::XML::Text.new(content.to_s, document)
          end

          private

          def emit(tag, content, attrs)
            node = Nokogiri::XML::Element.new(tag, document)
            attrs.each { |k, v| node[k.to_s] = v.to_s unless v.nil? }
            @stack.empty? ? document.root = node : current << node
            if block_given?
              @stack.push(node)
              begin
                result = yield
                text(result) if result.is_a?(String)
              ensure
                @stack.pop
              end
            elsif content
              node << Nokogiri::XML::Text.new(content.to_s, document)
            end
            node
          end

          def current
            @stack.last
          end
        end
      end
    end
  end
end
