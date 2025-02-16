# frozen_string_literal: true

require_relative '../../../validation/validator/result/failure'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        class Failure < WorkflowTemplate::Validation::Validator::Result::Failure
          def message(*)
            data.full_messages.to_sentence
          end
        end
      end
    end
  end
end
