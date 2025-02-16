# frozen_string_literal: true

require_relative '../state'
require_relative '../workflow/description'

module WorkflowTemplate
  module Definer
    module HasDefaultStateTransitionStrategy
      Workflow::Description.register(:initialize, :state) do |workflow|
        "state: #{workflow.default_state_transition_strategy}"
      end

      def default_state_transition_strategy(*args)
        case args.length
        when 0
          return @default_state_transition_strategy if defined? @default_state_transition_strategy
          if defined?(superclass) && superclass.respond_to?(:default_state_transition_strategy)
            return superclass.default_state_transition_strategy
          end

          :merge
        when 1 then @default_state_transition_strategy = State.normalize_transition_strategy(args[0])
        else raise Error, "Unexpected arguments for state transition strategy: '#{args}'"
        end
      end

      def freeze
        @default_state_transition_strategy = default_state_transition_strategy unless frozen?

        super
      end
    end
  end
end
