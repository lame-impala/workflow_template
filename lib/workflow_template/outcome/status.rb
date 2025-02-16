# frozen_string_literal: true

module WorkflowTemplate
  class Outcome
    class Status
      def initialize(handled: false, default: false)
        @handled = handled
        @default = default
        freeze
      end

      def handled?
        @handled
      end

      def handled!
        self.class.new(handled: true, default: default?)
      end

      def default?
        @default
      end

      def default!
        self.class.new(handled: handled?, default: true)
      end

      def inspect
        "handled=#{handled?} default=#{default?}"
      end
    end
  end
end
