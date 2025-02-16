# frozen_string_literal: true

require_relative '../error'
require_relative '../adapter/abstract/result/failure'
require_relative '../validator/result/success'
require_relative '../validator/result/failure'
require_relative '../result/failure'
require_relative '../result/success'

module WorkflowTemplate
  module Validation
    module Evaluation
      class Abstract
        attr_reader :name, :key, :context, :validator

        def initialize(name, key, context, validator)
          @name = name.to_sym
          @key = key&.to_sym
          @context = context.freeze
          @validator = validator
          freeze
        end

        def call(data)
          result = run_validator(data)
          evaluate(result)
        end

        def evaluate(_result)
          raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
        end

        def describe
          validator.describe
        end

        private

        def run_validator(data)
          input = key.nil? ? data : data[key]
          case context
          when nil then validator.call(input)
          else validator.call(input, context: data&.slice(*context))
          end
        end

        def to_failure(result)
          if result.is_a? Adapter::Abstract::Result::Failure
            Result::Failure.instance(name, key, result)
          else
            to_failure(Validator::Result::Failure.new(validator, data: result))
          end
        end
      end
    end
  end
end
