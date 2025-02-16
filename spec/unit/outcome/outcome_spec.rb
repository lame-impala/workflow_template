# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../support/test_model'
require_relative '../../../lib/workflow_template/outcome'
require_relative '../../../lib/workflow_template/state'
require_relative '../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  RSpec.describe Outcome do
    let(:state_class) { State.state_class(State::Adapter.fetch(:default)) }

    context 'when using delegate' do
      let(:delegate) do
        proc do
          ok do |result:, **|
            @result = result
          end
          error(:foo) do |**|
            @result = 'Foo'
          end
          error do |error:, **|
            @result = error
          end
        end
      end

      it 'handles ok path through delegate' do
        result = state_class.initial({ result: :foo }, :update, [])
        outcome = described_class.new(result.final)
        delegate = delegate()
        outcome.handle do
          delegate_to delegate
        end
        expect(@result).to eq(:foo)
      end

      it 'handles specific error through delegate' do
        result = state_class.initial({ error: :foo }, :update, [])
        outcome = described_class.new(result.final)
        delegate = delegate()
        outcome.handle do
          delegate_to delegate
        end
        expect(@result).to eq('Foo')
      end

      it 'handles generic error through delegate' do
        result = state_class.initial({ error: :bar }, :update, [])
        outcome = described_class.new(result.final)
        delegate = delegate()
        outcome.handle do
          delegate_to delegate
        end
        expect(@result).to eq(:bar)
      end
    end

    context 'with duplicate handler' do
      it 'raises error' do
        result = state_class.initial({ value: 5 }, :update, [])
        outcome = described_class.new(result.final)
        expect do
          outcome.handle do
            ok do |result|
              result[:value]
            end
            ok do |result|
              result[:value]
            end
            otherwise_unwrap
          end
        end.to raise_error(WorkflowTemplate::Error, "Handler for 'ok' unexpected")
      end
    end

    context 'with no validations defined' do
      context 'when ok and error handlers present' do
        let(:model) { TestModel.new(5) }
        let(:result) { state_class.initial(data, :update, []) }
        let(:retval) do
          described_class.new(result.final).handle do
            ok do |result|
              result[:model]
            end
            error do |result|
              result[:error]
            end
          end
        end

        context 'with ok result' do
          let(:data) { { model: model } }

          it 'returns return value of the ok block' do
            expect(retval).to eq(model)
          end
        end

        context 'with error result' do
          let(:data) { { error: :error } }

          it 'returns return value of the error block' do
            expect(retval).to eq(:error)
          end
        end
      end
    end

    context 'with validations defined' do
      let(:model) { TestModel.new(5) }
      let(:error) { nil }
      let(:data) { { model: model, error: error } }
      let(:proxy) do
        Validation::Builder::Proxy
          .instance(Adapters::Validation::ActiveModel, TestValidationCollection)
      end
      let(:validations) { [proxy.validate(:model)] }
      let(:result) { state_class.initial(data, :update, validations) }

      let(:retval) do
        described_class.new(result.final).handle do
          ok do |**|
            :ok
          end
          invalid do |**|
            :invalid
          end
          error do |**|
            :error
          end
        end
      end

      context 'with ok result' do
        it 'runs the ok block' do
          expect(retval).to eq(:ok)
        end
      end

      context 'with invalid result' do
        let(:model) { TestModel.new(-5) }

        it 'runs the invalid block' do
          expect(retval).to eq(:invalid)
        end
      end

      context 'with validated object nil' do
        let(:model) { nil }

        it 'runs the invalid block' do
          expect(retval).to eq(:invalid)
        end
      end

      context 'with error result' do
        let(:error) { :error }

        it 'runs the error block' do
          expect(retval).to eq(:error)
        end
      end
    end

    context 'with default missing' do
      let(:result) { state_class.initial({ value: 5, error: error }, :update, []) }

      let(:retval) do
        described_class.new(result.final).handle do
          error(:specific) do |error:, **|
            "Handled specific: #{error}"
          end
          error(Symbol) do |error:, **|
            "Handled symbol: #{error}"
          end
        end
      end

      context 'when specific error matched' do
        let(:error) { :specific }

        it 'raises error' do
          expect { retval }
            .to raise_error(WorkflowTemplate::Error, "Default handler missing for statuses: 'ok, error'")
        end
      end
    end

    context 'with error matchers' do
      let(:result) { state_class.initial({ value: 5, error: error }, :update, []) }

      let(:retval) do
        described_class.new(result.final).handle do
          error(:specific) do |error:, **|
            "Handled specific: #{error}"
          end
          error(Symbol) do |error:, **|
            "Handled symbol: #{error}"
          end
          error do |error:, **|
            "Handled default: #{error}"
          end
          otherwise_unwrap
        end
      end

      context 'when specific error matched' do
        let(:error) { :specific }

        it 'runs the specific error handler' do
          expect(retval).to eq('Handled specific: specific')
        end
      end

      context 'when symbol error matched' do
        let(:error) { :symbol }

        it 'runs the specific error handler' do
          expect(retval).to eq('Handled symbol: symbol')
        end
      end

      context 'when error not matched' do
        let(:error) { 'general' }

        it 'runs the specific error handler' do
          expect(retval).to eq('Handled default: general')
        end
      end
    end

    context 'with catchall block' do
      let(:result) { state_class.initial({ value: 5, error: error }, :update, []) }

      let(:retval) do
        described_class.new(result.final).handle do
          ok { 'ok retval' }
          otherwise { 'otherwise retval' }
        end
      end

      context 'when status is handled by specific handler' do
        let(:error) { nil }

        it 'returns handler block return value' do
          expect(retval).to eq('ok retval')
        end
      end

      context 'when status is handled by the catchall block' do
        let(:error) { :error }

        it 'returns catchall block return value' do
          expect(retval).to eq('otherwise retval')
        end
      end
    end

    context 'with otherwise_unwrap handler' do
      let(:result) { state_class.initial({ value: 5, error: error }, :update, []) }

      context 'when status is handled by specific handler' do
        let(:error) { nil }

        it 'returns handler block return value' do
          expect(described_class.new(result.final).handle(&:otherwise_unwrap)).to eq({ value: 5, error: nil })
        end
      end

      context 'when status is handled by the catchall block' do
        let(:error) { :error }

        it 'returns catchall block return value' do
          expect do
            described_class.new(result.final).handle(&:otherwise_unwrap)
          end.to raise_error(ExecutionError, 'error')
        end
      end
    end
  end
end
