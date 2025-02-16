# frozen_string_literal: true

require_relative '../../action'
require_relative 'insert'
require_relative 'inside'

module WorkflowTemplate
  module Definer
    module HasActions
      module Dsl
        def apply(action_name, **opts, &block)
          insert_action(action_name, position: :after, **opts, &block)
        end

        alias and_then apply

        def append_action(after: nil)
          Insert.new(self, :after, after)
        end

        def prepend_action(before: nil)
          Insert.new(self, :before, before)
        end

        def replace_action(name)
          Insert.new(self, :at, name)
        end

        def inside_action(name, &block)
          position = Inside.new(name, block)
          store_action(nil, position)
        end

        def wrap_template(action_name, **opts)
          action = Action.instance(action_name, :wrapper, **translate_action_parameters(**opts))
          store_wrapper_action(action)
        end

        def remove_action(action_name)
          position = Position.instance(:at, action_name)
          store_action(nil, position)
        end

        protected

        def insert_action(action_name, position: :after, reference: nil, **opts, &block)
          action = if block.nil?
            Action.instance(action_name, :simple, **translate_action_parameters(**opts), &block)
          else
            wrapper_action = Action.instance(action_name, :wrapper, **translate_action_parameters(**opts))
            Action::Nested::Unprepared.instance(wrapper_action, Nested::Unprepared, &block)
          end

          position = Position.instance(position, reference)
          store_action(action, position)
        end

        def translate_action_parameters(state: nil, validate: nil, **opts)
          { state_transition_strategy: state, validates: validate, **opts }
        end
      end
    end
  end
end
