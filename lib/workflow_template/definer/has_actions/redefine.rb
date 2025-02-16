# frozen_string_literal: true

require_relative 'position'

module WorkflowTemplate
  module Definer
    module HasActions
      module Redefine
        def redefine_onto(workflow_module, &block)
          target = Module.new do
            extend workflow_module
          end

          actions.wrapper.each do |action|
            target.send :store_wrapper_action, action
          end
          actions.simple.each do |action|
            position = Position.instance(:after, nil)
            target.send :store_action, action, position
          end
          target.instance_eval(&block)

          target.freeze
        end
      end
    end
  end
end
