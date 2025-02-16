# frozen_string_literal: true

require_relative 'adapter/abstract/builder'
require_relative 'adapter/abstract/validator'
require_relative 'adapter/abstract/result/failure'
require_relative 'validator/result/success'

module WorkflowTemplate
  module Validation
    module Adapter
      def self.registry
        @registry ||= {}
      end

      def self.register(name, adapter)
        registry[name.to_sym] = adapter
      end

      def self.fetch(name)
        name = name.to_sym
        raise Error, "Not a registered validation adapter: #{name}" unless registry.key? name

        registry[name]
      end

      def builder_class
        raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
      end

      def register(name)
        Adapter.register(name, self)
      end
    end
  end
end
