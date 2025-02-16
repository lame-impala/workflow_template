# frozen_string_literal: true

require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class TestSimple < Workflow
    declare_validation(using: :generic).validate(:valid) { _1 == true }

    apply(:action, validate: :valid)

    def action(outcome:, **)
      case outcome
      when :raise
        raise Error, 'BOO!'
      when :error
        { error: :boo! }
      when :invalid
        { valid: false }
      when :ok
        { model: :model, extra: :extra }
      end
    end

    freeze
  end
end
