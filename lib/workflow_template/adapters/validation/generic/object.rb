# frozen_string_literal: true

require_relative 'validator'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        class Object < Validator
          def initialize(object)
            @object = object
            super()
          end

          def describe
            object.respond_to?(:describe) ? object.describe : super
          end

          private

          attr_reader :object

          def call_foreign(value, **opts)
            object.call(value, **opts)
          end
        end
      end
    end
  end
end
