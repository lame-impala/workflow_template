# frozen_string_literal: true

require_relative '../../../validation/validator/result/failure'

module WorkflowTemplate
  module Adapters
    module Validation
      module DryValidation
        class Failure < WorkflowTemplate::Validation::Validator::Result::Failure
          def message(*)
            return if data.nil?

            data.errors(full: true).messages.map(&:text).join(', ')
          end
        end
      end
    end
  end
end
