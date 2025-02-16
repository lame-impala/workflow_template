# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_workflow'

module WorkflowTemplate
  RSpec.describe Workflow do
    let(:implementation) { TestWorkflow.new }
    let(:outcome) { TestWorkflow.perform(input, implementation, trace: true) }
    let(:trace) { outcome.meta.trace }

    context 'with correct input' do
      let(:input) { { model: TestModel.new(4) } }

      it 'performs all actions' do
        expect(trace).to eq(%i[add multiply])
      end

      it 'runs ok block' do
        result = outcome.handle do
          ok { |result| result[:model].value }
          otherwise_raise
        end

        expect(result).to eq((4 + 4) * 3)
      end
    end

    context 'when input invalid before run' do
      let(:input) { { model: TestModel.new(-4) } }

      it 'halts before performing any action' do
        expect(trace).to eq(%i[])
      end

      it 'stores validation failure into the state' do
        expect(outcome.data[:error]).to be_a(Validation::Result::Failure)
      end

      it 'runs invalid block' do
        result = outcome.handle do
          invalid { :invalid! }
          otherwise_raise
        end

        expect(result).to eq(:invalid!)
      end
    end

    context 'when error present in input before run' do
      let(:input) { { error: :FOO! } }

      it 'halts before performing any action' do
        expect(trace).to eq(%i[])
      end

      it 'keeps error in the state' do
        expect(outcome.data[:error]).to eq(:FOO!)
      end

      it 'runs error block' do
        result = outcome.handle do
          error { :error! }
          otherwise_raise
        end

        expect(result).to eq(:error!)
      end
    end

    context 'first action invalid' do
      let(:input) { { model: TestModel.new(24) } }

      it 'halts after first action' do
        expect(trace).to eq([:add])
      end

      it 'stores invalid model into the state' do
        expect(outcome.data[:model]).not_to be_valid
      end

      it 'runs invalid block' do
        result = outcome.handle do
          invalid { :invalid! }
          otherwise_raise
        end

        expect(result).to eq(:invalid!)
      end
    end

    context 'first action returns error' do
      let(:input) { { model: TestModel.new(44) } }

      it 'halts after first action' do
        expect(trace).to eq([:add])
      end

      it 'stores error into the state' do
        expect(outcome.data[:error].message).to eq('Too high: 44')
      end

      it 'runs error block' do
        result = outcome.handle do
          error { :error! }
          otherwise_raise
        end
        expect(result).to eq(:error!)
      end
    end

    context 'first action raises' do
      let(:input) { { model: TestModel.new(64) } }

      it 'halts after first action' do
        expect(trace).to eq([:add])
      end

      it 'stores error into the state' do
        expect(outcome.data[:error].message).to eq('Value too high: 64')
      end

      it 'runs error block' do
        result = outcome.handle do
          error { :error! }
          otherwise_raise
        end
        expect(result).to eq(:error!)
      end
    end

    context 'second action invalid' do
      let(:input) { { model: TestModel.new(1) } }

      it 'halts after second action' do
        expect(trace).to eq(%i[add multiply])
      end

      it 'stores invalid model into the state' do
        expect(outcome.data[:model]).not_to be_valid
      end

      it 'runs invalid block' do
        result = outcome.handle do
          invalid { :invalid! }
          otherwise_raise
        end
        expect(result).to eq(:invalid!)
      end
    end

    context 'second action returns error' do
      let(:input) { { model: TestModel.new(2) } }

      it 'halts after seconed action' do
        expect(trace).to eq(%i[add multiply])
      end

      it 'stores error into the state' do
        expect(outcome.data[:error].message).to eq('Not fit: 6')
      end

      it 'runs error block' do
        result = outcome.handle do
          error { :error! }
          otherwise_raise
        end
        expect(result).to eq(:error!)
      end
    end

    context 'second action raises' do
      let(:input) { { model: TestModel.new(3) } }

      it 'halts after seconed action' do
        expect(trace).to eq(%i[add multiply])
      end

      it 'stores error into the state' do
        expect(outcome.data[:error].message).to eq('Value not fit: 7')
      end

      it 'runs error' do
        result = outcome.handle do
          error { :error! }
          otherwise_raise
        end
        expect(result).to eq(:error!)
      end
    end

    context 'with unexpected error' do
      context 'when state class is not available' do
        let(:input) { {} }

        before { allow(State).to receive(:state_class) { raise 'Error!!!' } }

        it 'reraises the error' do
          expect { outcome }.to raise_error(Fatal, 'Unable to initialize state class: Error!!!')
        end
      end

      context 'with unexpected error during initialization' do
        let(:input) { {} }
        let(:faulty_class) do
          Module.new do
            def self.initial(*)
              raise 'Error!!!'
            end
          end
        end

        before { allow(State).to receive(:state_class).and_return(faulty_class) }

        it 'reraises the error' do
          expect { outcome }.to raise_error(Fatal, 'Unable to initialize state: Error!!!')
        end
      end

      context 'with unexpected error during processing' do
        let(:input) { { fail: true } }
        let(:faulty_class) do
          healthy_class = State.state_class(Adapters::State::Default)
          faulty_state = instance_double(State::Intermediate)
          allow(faulty_state).to receive(:continue?) { raise 'Error!!!' }

          faulty_class = Class.new(healthy_class)
          allow(faulty_class).to receive(:initial) { |input, default_strategy, validations|
            input[:fail] ? faulty_state : healthy_class.initial(input, default_strategy, validations)
          }
          faulty_class
        end

        before { allow(State).to receive(:state_class).and_return(faulty_class) }

        it 'reraises the error' do
          expect { outcome }.to raise_error(Fatal, 'Unexpected error: Error!!!')
        end
      end
    end
  end
end
