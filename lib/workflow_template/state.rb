# frozen_string_literal: true

require_relative 'state/intermediate'

module WorkflowTemplate
  module State
    STRATEGIES = %i[merge update].freeze

    def self.normalize_transition_strategy(strategy)
      strategy = strategy.to_sym
      raise Error, "Unimplemented strategy: '#{strategy}'" unless STRATEGIES.include?(strategy)

      strategy
    end

    def self.state_class(adapter)
      state_classes[adapter] ||= Class.new do
        include State::Intermediate
        extend State::ClassMethods

        raise Error, "Invalid adapter: #{adapter}" unless State.valid_adapter?(adapter)

        include adapter::InstanceMethods
        extend adapter::ClassMethods

        private_class_method :new
      end
    end

    def self.valid_adapter?(adapter)
      adapter.constants.include?(:InstanceMethods) &&
        adapter::InstanceMethods.included_modules.include?(Adapter::Abstract::InstanceMethods) &&
        adapter.constants.include?(:ClassMethods) &&
        adapter::ClassMethods.included_modules.include?(Adapter::Abstract::ClassMethods)
    end

    def self.state_classes
      @state_classes ||= {}
    end
  end
end
