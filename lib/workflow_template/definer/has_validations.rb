# frozen_string_literal: true

require_relative '../validation/adapter'
require_relative '../validation/builder/proxy'
require_relative '../adapters/validation/generic'
require_relative 'has_validations/validations'

module WorkflowTemplate
  module Definer
    module HasValidations
      def default_validation_adapter(*args)
        case args.length
        when 0
          return @default_validation_adapter if defined? @default_validation_adapter
          if defined?(superclass) && superclass.respond_to?(:default_validation_adapter)
            return superclass.default_validation_adapter
          end

          :default
        when 1 then @default_validation_adapter = args[0]
        else raise Error, "Unexpected arguments for default validation adapter: '#{args}'"
        end
      end

      def declare_validation(name = nil, using: default_validation_adapter)
        adapter = Validation::Adapter.fetch(using)

        Validation::Builder::Proxy
          .instance(adapter, own_validations, name: name)
      end

      def validate_input(keys)
        own_validations.validate_input(keys)
      end

      def validate_output(keys)
        own_validations.validate_output(keys)
      end

      def freeze
        unless frozen?
          @default_validation_adapter = default_validation_adapter
          @validations = validations.resolved
          @own_validations = nil
        end

        super
      end

      protected

      def prepare_action(action)
        super.prepare(validations)
      end

      def validations
        return @validations if defined? @validations
        return own_validations.prepared unless defined?(superclass) && superclass.respond_to?(:validations, true)

        superclass.validations.merge(own_validations)
      end

      private

      def own_validations
        @own_validations ||= Validations::Unprepared.instance
      end
    end
  end
end
