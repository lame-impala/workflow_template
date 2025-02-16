# frozen_string_literal: true

require_relative 'definer/has_actions'
require_relative 'definer/has_actions/root'
require_relative 'definer/has_default_state_transition_strategy'
require_relative 'definer/has_output_normalizer'
require_relative 'definer/has_state_adapter'
require_relative 'definer/has_validations'
require_relative 'definer/has_validations/description'
require_relative 'outcome'

require_relative 'performer'
require_relative 'workflow/description'

module WorkflowTemplate
  class Workflow
    module ModuleMethods
      include Definer::HasActions::Root
      include Definer::HasDefaultStateTransitionStrategy
      include Definer::HasOutputNormalizer
      include Definer::HasStateAdapter
      include Definer::HasValidations
      include Performer

      def perform(input, receiver, trace: false) # rubocop:disable Metrics/AbcSize
        state_class = State.state_class(state_adapter)
        state = state_class.initial(
          input,
          default_state_transition_strategy,
          validations.input_validations,
          trace: trace
        )
        state = super(state, receiver) if state.continue?
        state = state.normalize_data(output_normalizer)
        state = state.apply_validations(validations.output_validations)
        Outcome.new(state.final)
      rescue Fatal
        raise
      rescue StandardError => e
        raise Fatal, "Unable to initialize state class: #{e}" unless state_class
        raise Fatal, "Unable to initialize state: #{e}" unless state

        raise Fatal, "Unexpected error: #{e}"
      end

      def describe
        raise Error, "Can't describe unfrozen workflow" unless frozen?

        Description.describe(self)
      end
    end

    module ClassMethods
      attr_reader :impl

      def freeze
        @impl = new.freeze
        super
      end
    end

    extend ModuleMethods
    extend ClassMethods

    def perform(inputs, trace: false)
      self.class.perform(inputs, self, trace: trace)
    end
  end
end
