# frozen_string_literal: true

require_relative 'error'
require_relative '../evaluation'

module WorkflowTemplate
  module Validation
    module Builder
      class Proxy
        def self.instance(adapter, collection, name: nil, context: nil)
          new adapter, collection, normalize_name(name), normalize_context(context)
        end

        def self.normalize_name(name)
          return if name.nil?

          raise Error, 'Empty name' if name.empty?

          name.to_sym
        end

        def self.normalize_context(context)
          return if context.nil? || context.empty?

          raise Error, "Context contains invalid keys: #{context}" if context.any?(&:empty?)

          context.map(&:to_sym)
        end

        private_class_method :new

        def initialize(adapter, collection, name, context)
          @adapter = adapter
          @collection = collection
          @name = name&.to_sym
          @context = context.freeze
          freeze
        end

        attr_reader :name, :context

        def key?
          false
        end

        def key
          nil
        end

        def named(name)
          raise Error, "Name already defined: #{self.name}" if self.name

          self.class.instance(adapter, collection, name: name, context: context)
        end

        def with_context(*context)
          raise Error, "Context already defined: #{self.context}" if self.context

          self.class.instance(adapter, collection, name: name, context: context)
        end

        def validate(key = nil, **opts, &block)
          proxy = if key
            Keyed.instance(key, adapter, collection, name: name, context: context)
          else
            raise Error, 'Key must be supplied if name is missing' if name.nil?
            raise Error, 'Context is not available if key is not specified' unless context.nil?

            self
          end

          adapter.builder_class
                 .new(proxy)
                 .validate(**opts, &block)
        end

        def declare(validation)
          collection.add(evaluation(validation))
        end

        private

        attr_reader :adapter, :collection

        def evaluation(validation)
          evaluation_class.new(name, key, context, validation)
        end

        def evaluation_class
          case adapter.result_type
          when :boolean then Evaluation::Boolean
          when :canonical then Evaluation::Canonical
          else raise Error, "Unexpected result type: #{adapter.result_type}"
          end
        end

        class Keyed < Proxy
          def self.instance(key, adapter, collection, name: nil, context: nil)
            key = normalize_key(key)
            new key, adapter, collection, normalize_name(name) || key, normalize_context(context)
          end

          def self.normalize_key(key)
            return if key.nil?

            raise Error, 'Empty key' if key.empty?

            key.to_sym
          end

          def initialize(key, *args)
            @key = key.to_sym
            super(*args)
          end

          attr_reader :key

          def key?
            true
          end

          def validate(**opts, &block)
            adapter.builder_class.new(self).validate(**opts, &block)
          end
        end
      end
    end
  end
end
