# frozen_string_literal: true

require_relative 'validator'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        class Block < Validator
          def initialize(block)
            @block = block
            super()
          end

          private

          def call_foreign(object, **opts)
            @block.call(object, **opts)
          end
        end
      end
    end
  end
end
