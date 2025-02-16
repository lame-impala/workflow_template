# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_model'
require_relative '../support/test_validation_adapter'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class ValidatingWorkflow < WorkflowTemplate::Workflow
    default_validation_adapter :test

    declare_validation(:input_is_valid, using: :generic).validate do |state|
      state.keys.include?(:data) && state.keys.include?(:output)
    end
    declare_validation(:input_validation).validate(:data).to_not_eq(:invalid_input)
    declare_validation(:sequential_step1_validation).validate(:data).to_not_eq(:invalid_sequential_step1)
    declare_validation(:sequential_step2_validation).validate(:data).to_not_eq(:invalid_sequential_step2)
    declare_validation(:nesting_step_validation).validate(:data).to_not_eq(:invalid_nesting_step)
    declare_validation(:wrapper_block_validation).validate(:data).to_not_eq(:invalid_wrapper_block)
    declare_validation(:output_validation).validate(:data).to_not_eq(:invalid_output)

    validate_input(%i[input_validation input_is_valid])
    validate_output(:output_validation)

    wrap_template(:wrapper_block, validate: :wrapper_block_validation)
    apply(:sequential_step1, validate: :sequential_step1_validation)
    and_then(:nesting_step, validate: :nesting_step_validation) do
      apply(:sequential_step2, validate: :sequential_step2_validation)
    end

    def wrapper_block(data:, output:, &block)
      result = block.call(data: data, output: output)
      result[:output] << :wrapper
      result
    end

    def sequential_step1(data:, output:)
      { data: data, output: [*output, :seq1] }
    end

    def nesting_step(data:, output:, &block)
      result = block.call(data: data, output: output)
      result[:output] << :nesting
      result
    end

    def sequential_step2(data:, output:)
      { data: data, output: [*output, :seq2] }
    end

    freeze
  end

  class ValidationOverridingWorkflow < ValidatingWorkflow
    declare_validation(:input_validation)
      .validate(:data)
      .to_not_eq(:input_invalid_in_a_peculiar_way)

    freeze
  end

  class ValidatingActionWorkflow < WorkflowTemplate::Workflow
    declare_validation(using: :active_model).validate(:model)

    apply(:populate_model, validate: [:model])
    apply(:save_model)

    def populate_model(model:, value:)
      model.value = value
      { model: model }
    end

    def save_model(model:, **)
      model.save!
      { model: model }
    end

    freeze
  end

  RSpec.describe Workflow do
    context 'when state validation fails' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_input })
        expect(outcome.status).to eq(:error)
        expected_description = <<~DESC.chomp
          Value supposed not to equal invalid_input
        DESC
        expect(outcome.data[:error].message).to eq(expected_description)
      end
    end

    context 'when all validations pass' do
      it 'returns ok outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :valid, output: [] })
        expect(outcome.status).to eq(:ok)
        expect(outcome.data[:output]).to eq(%i[seq1 seq2 nesting wrapper])
      end
    end

    context 'when input validation fails' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :input_validation })
        expect(outcome.data[:error].name).to eq(:input_is_valid)
      end
    end

    context 'when validation fails in sequential step' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_sequential_step1, output: [] })
        expect(outcome.data[:error].name).to eq(:sequential_step1_validation)
        expect(outcome.data[:output]).to eq(%i[seq1 wrapper])
      end
    end

    context 'when validation fails in nested sequential step' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_sequential_step2, output: [] })
        expect(outcome.data[:error].name).to eq(:sequential_step2_validation)
        expect(outcome.data[:output]).to eq(%i[seq1 seq2 nesting wrapper])
      end
    end

    context 'when validation fails in nesting step' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_nesting_step, output: [] })
        expect(outcome.data[:error].name).to eq(:nesting_step_validation)
        expect(outcome.data[:output]).to eq(%i[seq1 seq2 nesting wrapper])
      end
    end

    context 'when validation fails in wrapper step' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_wrapper_block, output: [] })
        expect(outcome.data[:error].name).to eq(:wrapper_block_validation)
        expect(outcome.data[:output]).to eq(%i[seq1 seq2 nesting wrapper])
      end
    end

    context 'when output validation fails' do
      it 'returns error outcome' do
        outcome = ValidatingWorkflow.impl.perform({ data: :invalid_output, output: [] })
        expect(outcome.data[:error].name).to eq(:output_validation)
        expect(outcome.data[:output]).to eq(%i[seq1 seq2 nesting wrapper])
      end
    end

    context 'when validation is overridden' do
      it 'uses the overridden validation' do
        outcome = ValidationOverridingWorkflow.impl.perform({ data: :input_invalid_in_a_peculiar_way })
        expect(outcome.data[:error].name).to eq(:input_validation)
      end
    end

    context 'when result is valid' do
      it 'returns ok outcome' do
        model = TestModel.new(nil)
        outcome = ValidatingActionWorkflow.impl.perform({ model: model, value: 10 })
        expect(outcome.data[:model]).to be_valid
        expect(outcome.data[:model]).to be_saved
        expect(outcome.status).to eq(:ok)
      end
    end

    context 'when result is invalid' do
      it 'returns invalid outcome' do
        model = TestModel.new(nil)
        outcome = ValidatingActionWorkflow.impl.perform({ model: model, value: -10 })
        expect(outcome.data[:model]).not_to be_valid
        expect(outcome.data[:model]).not_to be_saved
        expect(outcome.data[:error]).to be_a(Validation::Result::Failure)
      end
    end
  end
end
