# frozen_string_literal: true

module Metanorma::Oiml::Sts::Source
  # Base class for all source adapters. Each subclass wraps one
  # typed-model class and exposes a stable, typed interface.
  #
  # The base class delegates unknown methods to the wrapped typed
  # object via method_missing, so simple accessors (id, anchor, type)
  # work automatically. Subclasses override methods that need special
  # handling (text extraction, child iteration, etc.).
  class Base
    attr_reader :typed

    def initialize(typed)
      @typed = typed
    end

    # Plain-text representation of the adapter's content.
    def text
      InlineExtractor.text_from(@typed)
    end

    # Delegate unknown methods to the typed model.
    ruby2_keywords def method_missing(name, *args, &block)
      if @typed.respond_to?(name)
        @typed.public_send(name, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      @typed.respond_to?(name) || super
    end
  end
end
