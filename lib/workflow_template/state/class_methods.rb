# frozen_string_literal: true

require_relative 'validation'

module WorkflowTemplate
  module State
    module ClassMethods
      def initial(input, default_strategy, validations, trace: false)
        wrapped_state = wrap_success(input)
        wrapped_state = validate(wrapped_state, validations)
        new wrapped_state, State.normalize_transition_strategy(default_strategy), Meta.instance(trace)
      end

      def validate(wrapped_state, validations)
        raise Fatal::BadInput, wrapped_state unless canonical? wrapped_state

        return wrapped_state if !Validation.applicable?(validations) || error?(wrapped_state)

        flat_map_unwrappable_state(wrapped_state) do |bare_state|
          result = Validation.validate(bare_state, validations)
          result.success? ? wrapped_state : wrap_error_with_bare_state(result, bare_state)
        end
      end

      def merge_bare_result(bare_state, bare_result, strategy, action_name)
        ensure_canonical_bare_result!(bare_result, action_name)

        if strategy == :merge
          bare_state.merge(bare_result)
        else
          bare_result
        end
      end

      def ensure_canonical_bare_result!(bare_result, action_name)
        raise Fatal::BadActionReturn.new(action_name, bare_result) unless bare_result.is_a?(Hash)

        faulty_keys = bare_result.keys.reject { _1.is_a?(Symbol) }
        raise Fatal::BadReturnKeys.new(action_name, faulty_keys) unless faulty_keys.empty?
      end
    end
  end
end
