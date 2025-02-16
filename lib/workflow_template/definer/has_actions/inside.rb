# frozen_string_literal: true

require_relative 'position'

module WorkflowTemplate
  module Definer
    module HasActions
      class Inside
        attr_reader :reference, :block

        def initialize(reference, block)
          @reference = reference
          @block = block
          freeze
        end

        def apply_onto(actions, action)
          raise Error, 'Action expected to be nil' unless action.nil?

          before, action, after = Position.slice_actions(actions, reference)
          clone = action.duplicate(&block)
          [*before, clone, *after]
        end
      end
    end
  end
end
