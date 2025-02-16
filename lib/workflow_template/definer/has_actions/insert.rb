# frozen_string_literal: true

module WorkflowTemplate
  module Definer
    module HasActions
      class Insert
        def initialize(workflow, position, reference)
          @workflow = workflow
          @position = position
          @reference = reference
        end

        def apply(action_name, **opts, &block)
          @workflow.send(
            :insert_action,
            action_name,
            position: @position,
            reference: @reference,
            **opts,
            &block
          )
          @workflow = nil
          nil
        end
      end
    end
  end
end
