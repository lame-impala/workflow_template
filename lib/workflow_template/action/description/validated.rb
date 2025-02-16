# frozen_string_literal: true

module WorkflowTemplate
  module Action
    module Description
      class Validated
        def self.instance(action)
          new action
        end

        private_class_method :new

        attr_reader :action

        def initialize(action)
          @action = action
          freeze
        end

        def format(level:)
          ["#{'  ' * level}#{self.class.describe(action)}"]
        end

        def self.describe(action)
          extras = [
            describe_defaults(action),
            describe_validations(action),
            describe_state_transition_strategy(action)
          ].compact
          return action.name if extras.empty?

          "#{action.name} #{extras.join(', ')}"
        end

        def self.describe_defaults(action)
          hash = action.defaults
          return if hash.nil? || hash.empty?

          "defaults: { #{hash.map { |key, value| "#{key}: #{value}" }.join(', ')} }"
        end

        def self.describe_validations(action)
          case action.validates
          when nil then nil
          when Array then "validates: #{action.validates.join(', ')}" unless action.validates.empty?
          else "validates: #{action.validates}"
          end
        end

        def self.describe_state_transition_strategy(action)
          return if action.state_transition_strategy.nil?

          "state: #{action.state_transition_strategy}"
        end
      end
    end
  end
end
