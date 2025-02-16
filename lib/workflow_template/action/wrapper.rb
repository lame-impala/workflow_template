# frozen_string_literal: true

require_relative 'validated'
require_relative 'description/wrapper'

module WorkflowTemplate
  module Action
    module Wrapper
      class Unprepared < Validated::Unprepared
        def prepare(validations)
          Prepared.instance(self, validations)
        end

        def describe(nested_actions)
          Description::Wrapper.instance(self, nested_actions)
        end
      end

      class Prepared < Validated::Prepared
        private

        def invoke_validated(state, receiver, *, &block)
          invoke_method state, receiver, &block
        end

        def handle_standard_error(error, state, *, **)
          state.class.wrap_error_with_bare_state(error, {})
        end
      end
    end
  end
end
