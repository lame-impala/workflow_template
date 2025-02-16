# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/validator'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        class Validator
          include WorkflowTemplate::Validation::Adapter::Abstract::Validator

          def call(object, **opts)
            call_foreign(object, **opts)
          rescue StandardError => e
            raise Fatal::ForeignCodeError, e
          end

          def describe
            "#{self.class.name.split('::').last.downcase} validation"
          end
        end
      end
    end
  end
end
