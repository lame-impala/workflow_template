# frozen_string_literal: true

require_relative '../../state/adapter'
require_relative '../../state/validation'

module WorkflowTemplate
  module Adapters
    module State
      module Default
        module InstanceMethods
          include WorkflowTemplate::State::Adapter::Abstract::InstanceMethods

          # Optimizations

          def halted?
            !!wrapped_state[:halted]
          end

          def error?
            !!wrapped_state[:error]
          end
        end

        module ClassMethods
          include WorkflowTemplate::State::Adapter::Abstract::ClassMethods

          def canonical?(wrapped_state)
            wrapped_state.is_a? Hash
          end

          def error?(wrapped_state)
            !!wrapped_state[:error]
          end

          def wrap_success(bare_state)
            bare_state
          end

          def unwrap_success(wrapped_state)
            wrapped_state
          end

          def wrap_error_with_bare_state(error, bare_state)
            { **bare_state, error: error }
          end

          def unwrap_error(wrapped_state)
            wrapped_state[:error]
          end

          def map_unwrappable_state(wrapped_state)
            yield wrapped_state
          end

          def flat_map_unwrappable_state(wrapped_state)
            yield wrapped_state
          end

          def run_handler!(state, binding, &block)
            if binding
              binding.receiver.instance_exec(**state.bare_state, &block)
            else
              block.call(**state.bare_state)
            end
          end
        end

        WorkflowTemplate::State::Adapter.register :default, self
      end
    end
  end
end
