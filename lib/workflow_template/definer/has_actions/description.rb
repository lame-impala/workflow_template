# frozen_string_literal: true

require_relative '../../workflow/description'

module WorkflowTemplate
  module Definer
    module HasActions
      class Description
        Workflow::Description.register(:perform, :actions) do |workflow|
          Description.new(workflow)
        end

        attr_reader :workflow

        def initialize(workflow)
          @workflow = workflow
          freeze
        end

        def format(level:)
          self.class.describe(workflow).flat_map { |action| action.format(level: level) }
        end

        def self.describe(workflow)
          describe_wrapper_actions(workflow.actions.wrapper, workflow.actions.simple)
        end

        def self.describe_wrapper_actions(wrapper_actions, simple_actions)
          action, *rest = wrapper_actions
          if action.nil?
            describe_actions(simple_actions)
          else
            [describe_wrapper_action(action, rest, simple_actions)]
          end
        end

        def self.describe_wrapper_action(action, rest, simple_actions)
          nested = describe_wrapper_actions(rest, simple_actions)
          action.describe(nested)
        end

        def self.describe_actions(actions)
          actions.map(&:describe)
        end
      end
    end
  end
end
