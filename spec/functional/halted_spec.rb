# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class HaltingWorkflow < Workflow
    default_state_transition_strategy :update

    apply(:increment_by_25)
    and_then(:increment_by_25)
    and_then(:increment_by_25)
    and_then(:increment_by_25)

    def increment_by_25(value:)
      return { value: value, halted: :too_high } if value > 75

      { value: value + 25 }
    end

    freeze
  end

  RSpec.describe Workflow do
    context 'when not halted' do
      let(:outcome) { HaltingWorkflow.impl.perform({ value: 0 }, trace: true) }

      it 'finishes with ok status' do
        expect(outcome.status).to eq(:ok)
      end

      it 'performs all actions' do
        expect(outcome.meta.trace).to eq(%i[increment_by_25 increment_by_25 increment_by_25 increment_by_25])
      end

      it "doesn't populate the halted key" do
        expect(outcome.data[:halted]).to be_nil
      end

      it 'stores return vlaue from the last action' do
        expect(outcome.data[:value]).to eq(100)
      end
    end

    context 'when halted' do
      let(:outcome) { HaltingWorkflow.impl.perform({ value: 51 }, trace: true) }

      it 'finishes with ok status' do
        expect(outcome.status).to eq(:ok)
      end

      it 'halts early' do
        expect(outcome.meta.trace).to eq(%i[increment_by_25 increment_by_25])
      end

      it 'populates the halted key' do
        expect(outcome.data[:halted]).to eq(:too_high)
      end

      it 'stores return value from the last action' do
        expect(outcome.data[:value]).to eq(76)
      end
    end
  end
end
