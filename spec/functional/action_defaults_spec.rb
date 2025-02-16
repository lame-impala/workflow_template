# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_logger'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class DefaultHavingWorkflow < Workflow
    default_state_transition_strategy :update

    wrap_template(:check_inputs, defaults: { threshold: 5 })

    apply(:log_inputs, defaults: { logger: proc { Logger.new(name: :default) } }) do
      and_then(:multiply, defaults: { multiplier: 2 })
    end

    def check_inputs(threshold:, **inputs, &block)
      if inputs[:value] > threshold
        { error: :over_limit }
      else
        block.call(**inputs)
      end
    end

    def log_inputs(logger:, **inputs, &block)
      logger = logger.call if logger.is_a? Proc
      logger.log("Inputs: #{inputs.inspect}")
      result = block.call(**inputs)
      { **result, logger: logger }
    end

    def multiply(value:, multiplier:)
      { result: value * multiplier }
    end
    freeze
  end

  RSpec.describe Workflow do
    context 'in simple and nested actions' do
      it 'supplies defaults' do
        outcome = DefaultHavingWorkflow.impl.perform({ value: 2 })
        expect(outcome.status).to eq(:ok)
        expect(outcome.data[:result]).to eq(4)
        expect(outcome.data[:logger].messages).to contain_exactly('Inputs: {:value=>2}')
      end

      it 'prefers explicit inputs' do
        logger = Logger.new(name: :explicit)
        outcome = DefaultHavingWorkflow.impl.perform({ value: 2, multiplier: 6, logger: logger })
        expect(outcome.status).to eq(:ok)
        expect(outcome.data[:result]).to eq(12)
        expect(outcome.data[:logger].name).to eq(:explicit)
        expect(outcome.data[:logger].messages).to contain_exactly('Inputs: {:value=>2, :multiplier=>6}')
      end
    end

    context 'in wrapper actions' do
      it 'supplies defaults' do
        outcome = DefaultHavingWorkflow.impl.perform({ value: 5 })
        expect(outcome.status).to eq(:ok)
        outcome = DefaultHavingWorkflow.impl.perform({ value: 6 })
        expect(outcome.status).to eq(:error)
      end

      it 'prefers explicit inputs' do
        outcome = DefaultHavingWorkflow.impl.perform({ value: 4, threshold: 4 })
        expect(outcome.status).to eq(:ok)
        outcome = DefaultHavingWorkflow.impl.perform({ value: 5, threshold: 4 })
        expect(outcome.status).to eq(:error)
      end
    end
  end
end
