# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/builder'
require_relative 'validator'

module WorkflowTemplate
  module Adapters
    module Validation
      module DryValidation
        class Builder < WorkflowTemplate::Validation::Adapter::Abstract::Builder
          def validate(contract:)
            proxy.declare(Validator.new(contract))
          end
        end
      end
    end
  end
end
