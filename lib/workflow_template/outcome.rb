# frozen_string_literal: true

require 'forwardable'
require_relative 'outcome/handler'
require_relative 'outcome/block'

module WorkflowTemplate
  class Outcome
    extend Forwardable

    def initialize(state)
      @handler = Handler.new(state)
    end

    def_delegator :handler, :retval
    def_delegator :handler, :final_state

    def_delegator :final_state, :meta
    def_delegator :final_state, :status
    def_delegator :final_state, :unwrap
    def_delegator :final_state, :fetch
    def_delegator :final_state, :slice
    def_delegator :final_state, :to_result

    def handle(&block)
      binding = block.binding unless block.source_location.nil?
      handler_block = Outcome::Block.new(handler, binding)

      handler_block.instance_eval(&block)

      self.handler = handler_block.handler
      ensure_default_handled!

      freeze

      handler.retval
    end

    def data
      final_state.bare_state
    end

    private

    def ensure_default_handled!
      return unless handler.default_missing?

      raise Error, "Default handler missing for statuses: '#{handler.default_missing.join(', ')}'"
    end

    attr_accessor :handler
  end
end
