# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_validation_adapter'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class WellDescribedWorkflow < Workflow
    default_state_transition_strategy :update
    default_validation_adapter :test
    declare_validation.validate(:logger).to_not_eq(nil)
    declare_validation.validate(:model).to_not_eq(:invalid_model)
    declare_validation.validate(:param).to_not_eq(:invalid_param)

    validate_input %i[param model]
    validate_output :model

    wrap_template :log, defaults: { current_user: :system }, validate: :logger

    apply(:init)
    and_then(:transaction, defaults: { timeout: 10 }, validate: :param, state: :update) do
      apply(:within_nested, validate: :model)
    end
    and_then(:finish, state: :update)

    normalize_output :param, :model
    freeze
  end

  RSpec.describe Workflow do
    describe '#describe' do
      it 'lists actions with padding' do
        description = WellDescribedWorkflow.describe
        expected = <<~DESC
          state: update
          validates input: { param, model }

          log defaults: { current_user: system }, validates: logger
            init
            transaction defaults: { timeout: 10 }, validates: param, state: update
              within_nested validates: model
            finish state: update

          normalizes output: param, model
          validates output: model
        DESC

        expect(description).to eq(expected)
      end
    end
  end
end
