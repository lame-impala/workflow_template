# frozen_string_literal: true

require_relative 'validated'

module WorkflowTemplate
  module Action
    module Description
      class Wrapper < Validated
        def self.instance(action, nested_actions)
          new action, nested_actions
        end

        private_class_method :new

        attr_reader :action, :nested_actions

        def initialize(action, nested_actions)
          @nested_actions = nested_actions.freeze
          super(action)
        end

        def format(level:)
          super + nested_actions.flat_map { |nested_action| nested_action.format(level: level + 1) }
        end
      end
    end
  end
end
