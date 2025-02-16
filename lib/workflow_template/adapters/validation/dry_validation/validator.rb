# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/validator'
require_relative '../../../validation/validator/result/success'
require_relative 'failure'

module WorkflowTemplate
  module Adapters
    module Validation
      module DryValidation
        class Validator
          extend WorkflowTemplate::Validation::Adapter::Abstract::Validator

          def initialize(contract_class)
            @contract_class = contract_class
          end

          def call(input, context: {})
            return Failure.new(self, code: :input_null) if input.nil?

            result = contract(context).call(input)
            return WorkflowTemplate::Validation::Validator::Result::Success if result.success?

            Failure.new(
              self,
              code: :input_invalid,
              data: result
            )
          end

          def describe
            'contract to be satisfied'
          end

          private

          attr_reader :contract_class

          def contract(context)
            contract_class.new(**context)
          end
        end
      end
    end
  end
end
