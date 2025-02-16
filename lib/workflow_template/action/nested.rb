# frozen_string_literal: true

require 'forwardable'
require_relative 'abstract'

module WorkflowTemplate
  module Action
    module Nested
      class Unprepared
        include Action::Abstract::Unprepared
        include Nested

        def self.instance(wrapper_action, workflow_module, &block)
          workflow = Module.new do
            extend workflow_module

            instance_eval(&block)
            send :store_wrapper_action, wrapper_action

            freeze
          end

          new(wrapper_action.name, workflow)
        end

        private_class_method :new
      end

      class Prepared
        extend Forwardable
        include Action::Abstract::Named
        include Action::Abstract::Prepared
        include Nested

        def_delegator :@workflow, :perform
      end

      def initialize(name, workflow)
        @workflow = workflow
        super(name)
      end

      def duplicate(&block)
        duplicate = @workflow.redefine(&block)

        Unprepared.send(:new, name, duplicate)
      end

      def prepare(*args)
        prepared = @workflow.prepare(*args)
        Prepared.send(:new, name, prepared)
      end

      def describe
        @workflow.describe
      end
    end
  end
end
