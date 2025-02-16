# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/builder'
require_relative 'validator'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        class Builder < WorkflowTemplate::Validation::Adapter::Abstract::Builder
          def validate
            proxy.declare(Validator)
          end
        end
      end
    end
  end
end
