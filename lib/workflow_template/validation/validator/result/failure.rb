# frozen_string_literal: true

require_relative '../../adapter/abstract/result/failure'

module WorkflowTemplate
  module Validation
    module Validator
      module Result
        class Failure
          include Adapter::Abstract::Result::Failure

          attr_reader :validator, :code, :data

          def initialize(validator, code: nil, data: nil)
            @validator = validator
            @code = code&.to_sym || :validation_failed
            @data = data
            freeze
          end

          def success?
            false
          end

          def describe
            validator.describe
          end

          def message(*)
            describe
          end
        end
      end
    end
  end
end
