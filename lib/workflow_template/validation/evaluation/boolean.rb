# frozen_string_literal: true

require_relative 'abstract'

module WorkflowTemplate
  module Validation
    module Evaluation
      class Boolean < Abstract
        def evaluate(result)
          result, detail = result
          if result
            case detail
            when nil then Result::Success
            when Hash, Array
              raise Fatal::BadValidationReturn, name unless detail.empty?

              Result::Success
            else
              raise Fatal::BadValidationReturn, name
            end
          else
            to_failure(detail)
          end
        end
      end
    end
  end
end
