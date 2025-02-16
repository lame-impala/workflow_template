# frozen_string_literal: true

require_relative '../validation/result/success'

module WorkflowTemplate
  module State
    module Validation
      def self.validate(data, validations)
        case validations
        when Array then validate_multiple(data, validations)
        else validations.call(data)
        end
      end

      def self.validate_multiple(data, validations)
        validations.reduce(WorkflowTemplate::Validation::Result::Success) do |result, validation|
          break result unless result.success?

          validation.call(data)
        end
      end

      def self.applicable?(validations)
        case validations
        when nil then false
        when Array then !validations.empty?
        else true
        end
      end
    end
  end
end
