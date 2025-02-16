# frozen_string_literal: true

require_relative 'validated'

module WorkflowTemplate
  module Action
    module Simple
      class Unprepared < Validated::Unprepared
        def prepare(validations)
          Prepared.instance(self, validations)
        end
      end

      class Prepared < Validated::Prepared
        private

        def invoke_validated(state, receiver)
          result = invoke_method(state, receiver)
          state.process_wrapped_result(result, self, trace: true, validate: true)
        end

        def handle_standard_error(error, state)
          state.merge_error(error, self)
        end
      end
    end
  end
end
