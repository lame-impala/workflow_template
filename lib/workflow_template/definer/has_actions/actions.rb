# frozen_string_literal: true

require_relative '../../error'

module WorkflowTemplate
  module Definer
    module HasActions
      module Actions
        class Unprepared
          def self.instance
            new
          end

          def initialize(simple: [], wrapper: [])
            @unprepared_simple = simple.freeze
            @unprepared_wrapper = wrapper.freeze
          end

          private_class_method :new

          def add_simple(action, position)
            @unprepared_simple = [*@unprepared_simple, [action, position]].freeze
          end

          def add_wrapper(action)
            @unprepared_wrapper = [action, *@unprepared_wrapper].freeze
          end

          def prepared
            simple = prepare_simple(existing: [])
            wrapper = prepare_wrapper(existing: [])

            Prepared.new(simple: simple, wrapper: wrapper)
          end

          protected

          attr_reader :unprepared_simple, :unprepared_wrapper

          def prepare_simple(existing:)
            unprepared_simple.reduce(existing) do |existing, (action, position)|
              position.apply_onto(existing, action)
            end
          end

          def prepare_wrapper(existing:)
            unprepared_wrapper + existing
          end
        end

        class Prepared
          attr_reader :simple, :wrapper

          def initialize(simple:, wrapper:)
            @simple = simple.freeze
            @wrapper = wrapper.freeze
            freeze
          end

          def merge(unprepared)
            simple = unprepared.send(:prepare_simple, existing: self.simple)
            wrapper = unprepared.send(:prepare_wrapper, existing: self.wrapper)

            Prepared.new(simple: simple, wrapper: wrapper)
          end

          def map(&block)
            simple_actions = simple.map(&block)
            wrapper_actions = wrapper.map(&block)
            self.class.new simple: simple_actions, wrapper: wrapper_actions
          end

          def next_wrapper_action
            return [nil, self] if wrapper.empty?

            action, *rest = wrapper
            container = self.class.new(simple: simple, wrapper: rest)
            [action, container]
          end

          def inspect
            simple = simple().map(&:name).join(', ')
            wrapper = wrapper().map(&:name).join(', ')
            "#<#{self.class.name} simple=[#{simple}] wrapper=[#{wrapper}]>"
          end
        end
      end
    end
  end
end
