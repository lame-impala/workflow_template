# frozen_string_literal: true

require_relative '../../lib/workflow_template/validation/adapter'
require_relative '../../lib/workflow_template/validation/validator/result/failure'

module WorkflowTemplate
  class TestValidationAdapter
    class Builder < Validation::Adapter::Abstract::Builder
      def to_not_eq(value)
        raise Builder::Error, 'Key is missing' unless proxy.key?

        validator = Validator.new(proxy.name, proxy.key, value)
        proxy.declare(validator)
      end
    end

    class Validator
      include Validation::Adapter::Abstract::Validator

      attr_reader :name, :key

      def initialize(name, key, value)
        @name = name.to_sym
        @key = key.to_sym
        @value = value.dup.freeze
        freeze
      end

      def call(data)
        return Validation::Validator::Result::Success unless @value == data

        Validation::Validator::Result::Failure.new(self, code: :invalid, data: data)
      end

      def describe
        "Value supposed not to equal #{@value}"
      end
    end

    def self.builder_class
      Builder
    end

    def self.result_type
      :canonical
    end

    Validation::Adapter.register(:test, self)
  end
end
