# frozen_string_literal: true

require 'spec_helper'
require_relative('../../lib/workflow_template/workflow')

module WorkflowTemplate
  class NestedWorkflow < Workflow
    default_state_transition_strategy :update
    declare_validation(using: :generic).validate(:model) { _1 != :invalid_model }

    wrap_template :measure
    wrap_template :log, defaults: { current_user: :system }

    apply(:init)
    and_then(:transaction, defaults: { timeout: 10 }) do
      apply(:within_nested, validate: :model)
    end
    and_then(:finish)

    def init(**input)
      { **input, model: :valid_model }
    end

    def log(**opts, &block)
      block.call(**opts)
    end

    def measure(**opts, &block)
      block.call(**opts)
    end

    def within_nested(outcome:, transaction:, **)
      raise 'Transaction not open' unless transaction == :open

      case outcome
      when :ok
        { model: :transformed_model }
      when :invalid
        { model: :invalid_model }
      when :error
        { error: :error_within_nested }
      when :raise
        raise Error, 'Bad thing happened'
      else
        raise "Unexpected outcome: #{outcome}"
      end
    end

    def transaction(**input)
      result = yield({ **input, transaction: :open })
      { **result, transaction: :closed }
    rescue StandardError => e
      { transaction: :closed, error: e }
    end

    def finish(**outcome)
      outcome
    end

    freeze
  end

  RSpec.describe Workflow do
    describe '#describe' do
      it 'lists actions with padding' do
        description = NestedWorkflow.describe
        expected = <<~DESC
          state: update

          log defaults: { current_user: system }
            measure
              init
              transaction defaults: { timeout: 10 }
                within_nested validates: model
              finish
        DESC
        expect(description).to eq(expected)
      end
    end

    context 'with valid input' do
      it 'runs nested block' do
        result = NestedWorkflow.impl.perform({ outcome: :ok }).handle do
          ok do |result|
            expect(result[:transaction]).to eq(:closed)
            result[:model]
          end
          otherwise_unwrap
        end
        expect(result).to eq(:transformed_model)
      end
    end

    context 'with invalid input' do
      it 'nested block halts processing' do
        result = NestedWorkflow.impl.perform({ outcome: :invalid }).handle do
          invalid do |result|
            expect(result[:transaction]).to eq(:closed)
            result[:model]
          end
          otherwise_unwrap
        end
        expect(result).to eq(:invalid_model)
      end
    end

    context 'reporting error' do
      it 'nested block halts processing' do
        result = NestedWorkflow.impl.perform({ outcome: :error }).handle do
          error do |result|
            expect(result[:transaction]).to eq(:closed)
            result[:error]
          end
          otherwise_unwrap
        end
        expect(result).to eq(:error_within_nested)
      end
    end

    context 'raising error' do
      it 'nested block halts processing' do
        result = NestedWorkflow.impl.perform({ outcome: :raise }).handle do
          error do |result|
            expect(result[:transaction]).to eq(:closed)
            result[:error]
          end
          otherwise_unwrap
        end
        expect(result.message).to eq('Bad thing happened')
      end
    end
  end
end
