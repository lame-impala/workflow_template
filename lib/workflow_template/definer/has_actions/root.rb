# frozen_string_literal: true

require_relative 'dsl'

module WorkflowTemplate
  module Definer
    module HasActions
      module Root
        include HasActions
        include Dsl

        def prepare_actions
          actions.map { prepare_action(_1) }
        end

        def prepare_action(action)
          action
        end
      end
    end
  end
end
