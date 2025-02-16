# frozen_string_literal: true

require_relative 'abstract'

module WorkflowTemplate
  module Validation
    module Evaluation
      class Canonical < Abstract
        def evaluate(result)
          case result
          when Validator::Result::Success then Result::Success
          when Adapter::Abstract::Result::Failure
            to_failure(result)
          else
            raise Fatal::BadValidationReturn, name
          end
        end
      end
    end
  end
end
