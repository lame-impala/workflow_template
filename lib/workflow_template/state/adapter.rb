# frozen_string_literal: true

require_relative '../error'

module WorkflowTemplate
  module State
    module Adapter
      def self.adapters
        @adapters ||= {}
      end

      def self.register(name, adapter)
        adapters[name.to_sym] = adapter
      end

      def self.fetch(name)
        name = name.to_sym
        raise Error, "Not a registered state adapter: #{name}" unless adapters.key? name

        adapters[name]
      end

      module Abstract
        module InstanceMethods
        end

        module ClassMethods
          def canonical?(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def error?(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def wrap_success(_bare_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def unwrap_success(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def wrap_error_with_bare_state(_error, _bare_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def unwrap_error(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def map_unwrappable_state(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def flat_map_unwrappable_state(_wrapped_state)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def run_handler!(state, binding, &block)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end
        end
      end
    end
  end
end
