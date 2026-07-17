# frozen_string_literal: true

module Metanorma::Oiml::Sts::Source
  # Registry mapping typed-model classes to their adapters.
  # Open/Closed: adding a new adapter = adding one entry here.
  class Registry
    @adapters = {}

    class << self
      def register(typed_class, adapter_class)
        @adapters[typed_class.name] = adapter_class
      end

      def adapter_for(typed_class)
        # Exact match first
        adapter = @adapters[typed_class.name]
        return adapter if adapter

        # Walk up the ancestor chain
        typed_class.ancestors.each do |ancestor|
          adapter = @adapters[ancestor.name]
          return adapter if adapter
        end

        nil
      end

      def all_adapters
        @adapters.dup
      end
    end
  end
end
