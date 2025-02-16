# frozen_string_literal: true

require_relative '../../error'

module WorkflowTemplate
  module Definer
    module HasActions
      class Position
        def self.instance(type, reference)
          case type
          when :before
            Position::Before.new(reference)
          when :after
            Position::After.new(reference)
          when :at
            raise Error, 'Reference not expected to be nil' if reference.nil?

            Position::At.new(reference)
          else
            raise Error, "Unexpected position: #{type}"
          end
        end

        def self.slice_actions(actions, reference)
          index, *rest = actions.each_index.reduce([]) do |result, index|
            next result unless actions[index].name == reference

            [*result, index]
          end
          raise Error, "Reference not found: #{reference}" if index.nil?
          raise Error, "Duplicate action name: #{reference}" if rest.length.positive?

          before = actions[0...index]
          action = actions[index]
          after = actions[(index + 1)..]
          [before, action, after]
        end

        def initialize(reference)
          @reference = reference&.to_sym
          freeze
        end

        def apply_onto(actions, action)
          if reference.nil?
            apply_without_reference(actions, action)
          else
            before, reference, after = self.class.slice_actions(actions, self.reference)
            apply_with_reference(before, action, reference, after)
          end
        end

        attr_reader :reference

        class Before < Position
          def apply_without_reference(actions, action)
            [action, *actions]
          end

          def apply_with_reference(before, action, reference, after)
            [*before, action, reference, *after]
          end
        end

        class After < Position
          def apply_without_reference(actions, action)
            [*actions, action]
          end

          def apply_with_reference(before, action, reference, after)
            [*before, reference, action, *after]
          end
        end

        class At < Position
          def apply_with_reference(before, action, _reference, after)
            action.nil? ? [*before, *after] : [*before, action, *after]
          end
        end
      end
    end
  end
end
