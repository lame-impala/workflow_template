# frozen_string_literal: true

module WorkflowTemplate
  module State
    class Meta
      module Null
        def self.add(*)
          self
        end

        def self.trace
          nil
        end

        freeze
      end

      attr_reader :trace

      def self.instance(trace)
        trace ? new : Null
      end

      private_class_method :new

      def initialize(trace: [])
        @trace = trace.freeze
      end

      def add(name)
        self.class.send :new, trace: [*@trace, name]
      end
    end
  end
end
