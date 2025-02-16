# frozen_string_literal: true

require_relative 'meta'

module WorkflowTemplate
  module State
    module Abstract
      attr_reader :wrapped_state, :meta

      def initialize(wrapped_state, meta)
        @wrapped_state = wrapped_state.freeze
        @meta = meta.freeze
        freeze
      end

      def bare_state
        state_class.unwrap_success(wrapped_state)
      end

      def error?
        state_class.error?(wrapped_state)
      end

      def error
        state_class.unwrap_error(wrapped_state)
      end

      def state_class
        raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
      end
    end
  end
end
