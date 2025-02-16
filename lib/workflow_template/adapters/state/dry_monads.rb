# frozen_string_literal: true

require 'dry/monads'
require_relative '../../state/adapter'

module WorkflowTemplate
  module Adapters
    module State
      module DryMonads
        module Handler
          extend Dry::Monads[:result]
        end

        module InstanceMethods
          include WorkflowTemplate::State::Adapter::Abstract::InstanceMethods
        end

        module ClassMethods
          include WorkflowTemplate::State::Adapter::Abstract::ClassMethods

          def canonical?(wrapped_state)
            wrapped_state.is_a? Dry::Monads::Result
          end

          def error?(wrapped_state)
            wrapped_state.failure?
          end

          def wrap_success(bare_state)
            Dry::Monads::Success(bare_state)
          end

          def unwrap_success(wrapped_state)
            raise Fatal::InconsistentState, "Expected Success, got #{wrapped_state}" unless wrapped_state.success?

            wrapped_state.success
          end

          def wrap_error_with_bare_state(error, _bare_state)
            Dry::Monads::Failure(error)
          end

          def unwrap_error(wrapped_state)
            raise Fatal::InconsistentState, "Expected Failure, got #{wrapped_state}" unless wrapped_state.failure?

            wrapped_state.failure
          end

          def map_unwrappable_state(wrapped_state, &block)
            wrapped_state.fmap(&block)
          end

          def flat_map_unwrappable_state(wrapped_state, &block)
            wrapped_state.bind(&block)
          end

          def run_handler!(state, _binding, &block)
            if state.error?
              state.wrapped_state.or { Handler.instance_exec(state.error, &block) }
            else
              state.wrapped_state.bind { Handler.instance_exec(**state.bare_state, &block) }
            end
          end
        end

        WorkflowTemplate::State::Adapter.register(:dry_monads, self)
      end
    end
  end
end
