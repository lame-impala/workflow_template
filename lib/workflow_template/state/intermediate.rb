# frozen_string_literal: true

require_relative 'class_methods'
require_relative 'final'

module WorkflowTemplate
  module State
    module Intermediate
      include Abstract

      def initialize(wrapped_state, default_strategy, meta)
        @default_strategy = default_strategy
        super(wrapped_state, meta)
      end

      attr_reader :default_strategy

      def continue?
        !(error? || halted?)
      end

      def halted?
        !!bare_state[:halted]
      end

      def final
        Final.new(wrapped_state, meta, self.class)
      end

      def apply_validations(validations)
        return self if error?

        wrapped_state = self.class.validate(self.wrapped_state, validations)
        self.class.send :new, wrapped_state, default_strategy, meta
      end

      def merge_error(error, action)
        return wrapped_state if error?

        wrapped_state = self.class.wrap_error_with_bare_state(error, {})
        process_wrapped_result(wrapped_state, action, trace: true, validate: false)
      end

      def normalize_data(normalizer)
        wrapped_state = normalize(normalizer)
        self.class.send :new, wrapped_state, default_strategy, meta
      end

      def process_bare_result(bare_result, action, trace:, validate:)
        process_result(action, trace, validate) do |strategy, action_name|
          self.class.map_unwrappable_state(wrapped_state) do |bare_state|
            self.class.merge_bare_result(bare_state, bare_result, strategy, action_name)
          end
        end
      end

      def process_wrapped_result(wrapped_result, action, trace:, validate:)
        process_result(action, trace, validate) do |strategy, action_name|
          if wrapped_result.nil?
            raise Fatal::UnexpectedNil, action_name if strategy == :update

            wrapped_state
          else
            raise Fatal::BadActionReturn.new(action_name, wrapped_result) unless self.class.canonical?(wrapped_result)

            self.class.flat_map_unwrappable_state(wrapped_state) do |bare_state|
              self.class.map_unwrappable_state(wrapped_result) do |bare_result|
                self.class.merge_bare_result(bare_state, bare_result, strategy, action_name)
              end
            end
          end
        end
      end

      def state_class
        self.class
      end

      private

      def process_result(action, trace, validate, &block)
        meta = trace ? self.meta.add(action.name) : self.meta

        strategy = action.state_transition_strategy || default_strategy
        wrapped_result = block.call(strategy, action.name)
        validations = action.validations if validate
        wrapped_state = self.class.validate(wrapped_result, validations)

        self.class.send :new, wrapped_state, default_strategy, meta
      end

      def normalize(normalizer)
        self.class.map_unwrappable_state(wrapped_state) do |bare_state|
          normalized = normalizer.normalize(bare_state)
          next normalized unless error?

          self.class.wrap_error_with_bare_state(self.class.unwrap_error(wrapped_state), normalized)
        end
      end
    end
  end
end
