# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/validator'
require_relative '../../../validation/validator/result/success'
require_relative 'failure'
require_relative 'null_model'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        class Validator
          extend WorkflowTemplate::Validation::Adapter::Abstract::Validator

          def self.call(input)
            model = input || NullModel.new
            return WorkflowTemplate::Validation::Validator::Result::Success if model.valid?

            code = input ? "#{model.model_name.singular}_invalid" : :model_nil

            Failure.new(
              self,
              code: code,
              data: model.errors
            )
          end

          def self.describe
            'model to be valid'
          end
        end
      end
    end
  end
end
