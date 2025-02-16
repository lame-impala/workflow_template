# frozen_string_literal: true

require_relative '../../../validation/adapter/abstract/builder'
require_relative 'object'
require_relative 'block'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        class Builder < WorkflowTemplate::Validation::Adapter::Abstract::Builder
          class Error < WorkflowTemplate::Error; end

          def validate(&block)
            return self unless block

            proxy.declare(Generic::Block.new(block))
          end

          def using(implementation)
            validator = Generic::Object.new(implementation)
            proxy.declare(validator)
          end
        end
      end
    end
  end
end
