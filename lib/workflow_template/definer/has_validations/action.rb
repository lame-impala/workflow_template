# frozen_string_literal: true

module WorkflowTemplate
  module Definer
    module HasValidations
      class Action
        def initialize(action, validations)
          @action = action
          @validations = validations
        end

        attr_reader :validations

        private

        attr_reader :action
      end
    end
  end
end
