# frozen_string_literal: true

require_relative 'error'

module WorkflowTemplate
  module Performer
    def perform(state, receiver)
      raise WorkflowTemplate::Fatal, 'Workflow is not frozen' unless frozen?

      Performer.perform_wrapper_actions(state, actions, receiver)
    end

    def self.perform_wrapper_actions(state, actions, receiver)
      if actions.wrapper.empty?
        perform_actions(state, actions, receiver)
      else
        action, container = actions.next_wrapper_action
        perform_wrapper_action(action, container, state, receiver)
      end
    end

    def self.perform_wrapper_action(action, container, state, receiver)
      inner_state = state
      result = action.perform(state, receiver) do |yielded = {}|
        inner_state = state.process_bare_result(yielded, action, trace: true, validate: false)
        inner_state = perform_wrapper_actions(inner_state, container, receiver)
        inner_state.wrapped_state
      end
      inner_state.process_wrapped_result(result, action, trace: false, validate: true)
    end

    def self.perform_actions(state, actions, receiver)
      actions.simple.reduce(state) do |intermediate, action|
        intermediate = perform_action(action, intermediate, receiver)

        break intermediate unless intermediate.continue?

        intermediate
      end
    end

    def self.perform_action(action, state, *args)
      action.perform(state, *args)
    end
  end
end
