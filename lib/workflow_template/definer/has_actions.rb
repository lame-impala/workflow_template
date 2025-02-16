# frozen_string_literal: true

require_relative '../performer'
require_relative 'has_actions/actions'
require_relative 'has_actions/nested'

module WorkflowTemplate
  module Definer
    module HasActions
      def actions
        return @actions if frozen?

        @own_actions ||= Actions::Unprepared.instance
        return @own_actions.prepared unless defined?(superclass) && superclass.respond_to?(:actions)

        superclass.actions.merge(@own_actions)
      end

      def freeze
        unless frozen?
          @actions = prepare_actions
          @own_actions = nil
        end

        super
      end

      protected

      def prepare_actions
        actions
      end

      def store_action(action, position)
        @own_actions ||= Actions::Unprepared.instance
        @own_actions.add_simple(action, position)
      end

      def store_wrapper_action(action)
        @own_actions ||= Actions::Unprepared.instance
        @own_actions.add_wrapper(action)
      end
    end
  end
end
