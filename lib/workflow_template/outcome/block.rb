# frozen_string_literal: true

require_relative '../validation/result/failure'

module WorkflowTemplate
  class Outcome
    class Block
      attr_reader :handler

      def initialize(handler, binding)
        @handler = handler
        @binding = binding
      end

      def ok(&block)
        handle_status(:ok, &block)
      end

      def invalid(&block)
        handle_status(:error, matcher: Validation::Result::Failure, &block)
      end

      def error(match = nil, &block)
        handle_status(:error, matcher: match, &block)
      end

      def otherwise(&block)
        self.handler = handler.otherwise(binding: binding, &block)
      end

      def otherwise_unwrap(slice: nil, fetch: nil)
        self.handler = handler.otherwise_unwrap(slice: slice, fetch: fetch)
      end

      def otherwise_raise(error: nil)
        handler = handler()
        self.handler = handler.otherwise(binding: binding) do |_|
          error ||= Error.new("Unhandled workflow status: '#{handler.final_state.status}'")
          raise error
        end
      end

      def delegate_to(proc)
        instance_eval(&proc)
      end

      private

      attr_reader :binding
      attr_writer :handler

      def handle_status(status, **opts, &block)
        self.handler = handler.handle_status(status, binding: binding, **opts, &block)
        self
      end
    end
  end
end
