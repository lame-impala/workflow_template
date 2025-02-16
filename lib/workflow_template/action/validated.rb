# frozen_string_literal: true

require 'forwardable'
require_relative 'abstract'
require_relative 'description/validated'

module WorkflowTemplate
  module Action
    module Validated
      class Unprepared
        include Abstract::Unprepared

        def self.normalize_validation_names(option)
          return if option.nil?
          return option.map(&:to_sym).freeze if option.is_a?(Array)

          option.to_sym.freeze
        end

        attr_reader :defaults, :validates, :state_transition_strategy

        def initialize(name, defaults: nil, validates: nil, state_transition_strategy: nil)
          @defaults = defaults.freeze
          @validates = self.class.normalize_validation_names(validates)

          unless state_transition_strategy.nil?
            @state_transition_strategy = State.normalize_transition_strategy(state_transition_strategy)
          end
          super(name)
        end

        def prepare(*args)
          raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
        end

        def describe
          Description::Validated.instance(self)
        end
      end

      class Prepared
        include Abstract::Prepared
        extend Forwardable

        FATAL_SUBCLASSES = Fatal.constants.map { |name| Fatal.const_get(name) }.freeze

        def_delegators :unprepared, :defaults
        def_delegators :unprepared, :describe
        def_delegators :unprepared, :name
        def_delegators :unprepared, :state_transition_strategy
        def_delegators :unprepared, :validates

        def self.instance(unprepared, validations)
          new unprepared, validations.resolve_validations(unprepared.validates)
        end

        def initialize(unprepared, validations)
          @unprepared = unprepared
          @validations = validations
          freeze
        end

        private_class_method :new

        def prepare(validations)
          self.class.instance(unprepared, validations)
        end

        attr_reader :unprepared, :validations

        def perform(state, receiver, &block)
          invoke_validated(state, receiver, &block)
        rescue *FATAL_SUBCLASSES
          raise
        rescue Fatal => e
          detailed = Fatal::Detailed.new(name, state.bare_state, e.message)
          raise detailed
        rescue ArgumentError => e
          invocation = method(:invoke_validated)
          raise Fatal::ArgumentError.new(name, e.message) if Fatal::ArgumentError.depth(e, invocation) == 2

          handle_standard_error(e, state)
        rescue StandardError => e
          handle_standard_error(e, state)
        end

        private

        def invoke_method(state, receiver, &block)
          raise Fatal::Unimplemented, name unless receiver.respond_to? name

          input = with_defaults(state.bare_state)
          receiver.send(name, **input, &block)
        end

        def with_defaults(input)
          return input if defaults.nil?

          defaults.merge(input)
        end
      end
    end
  end
end
