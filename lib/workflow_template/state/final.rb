# frozen_string_literal: true

require_relative 'abstract'
require_relative 'normalizer'
require_relative '../validation/result/failure'
require_relative '../validation/error'
require_relative '../error'

module WorkflowTemplate
  module State
    class Final
      include Abstract

      attr_reader :wrapped_state, :meta, :state_class

      def initialize(wrapped_state, meta, state_class)
        @state_class = state_class
        super(wrapped_state, meta)
      end

      def status
        error? ? :error : :ok
      end

      def unwrap(slice: nil, fetch: nil)
        raise_error! if error?
        return bare_state if slice.nil? && fetch.nil?

        normalized_bare_state = Normalizer.instance(slice).normalize(bare_state)
        fetch.nil? ? normalized_bare_state.values : normalized_bare_state.fetch(fetch, nil)
      end

      def fetch(key)
        unwrap(fetch: key)
      end

      def slice(*keys)
        unwrap(slice: keys)
      end

      def to_result(adapter = nil, **opts)
        error? ? rewrap_error(adapter) : rewrap_success(adapter, **opts)
      end

      def raise_error!
        error = state_class.unwrap_error(wrapped_state)

        case error
        when Exception then raise error
        when WorkflowTemplate::Validation::Result::Failure then raise WorkflowTemplate::Validation::Error, error
        else raise ExecutionError, error
        end
      end

      private

      def rewrap_error(adapter)
        return wrapped_state if adapter.nil? || target_class(adapter).canonical?(wrapped_state)

        target_class(adapter).wrap_error_with_bare_state(state_class.unwrap_error(wrapped_state), {})
      end

      def rewrap_success(adapter, **opts)
        target_class(adapter).wrap_success(unwrap(**opts))
      end

      def target_class(adapter)
        return state_class if adapter.nil?

        State.state_class(State::Adapter.fetch(adapter))
      end
    end
  end
end
