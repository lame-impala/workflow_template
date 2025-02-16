# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../support/test_model'
require_relative '../../lib/workflow_template/adapters/validation/generic'
require_relative '../../lib/workflow_template/validation/builder/proxy'
require_relative '../../lib/workflow_template/state'
require_relative '../../lib/workflow_template/state/adapter'
require_relative '../../lib/workflow_template/adapters/state/default'

module WorkflowTemplate
  RSpec.describe State do
    subject(:state_class) { described_class.state_class(State::Adapter.fetch(:default)) }

    let(:proxy) do
      Validation::Builder::Proxy
        .instance(Adapters::Validation::ActiveModel, TestValidationCollection)
    end

    let(:failing_validation) do
      proxy.named(:model_is_valid).validate(:model)
    end
    let(:failing_validations) { [failing_validation] }
    let(:validations) { [] }
    let(:state) do
      state_class.initial(data, :update, validations)
    end

    describe '#normalize_data' do
      let(:state) do
        state_class.send(
          :new,
          { foo: :not_normalized, bar: :normalized, error: :error },
          :update,
          State::Meta.instance(true).add(:foo)
        )
      end
      let(:normalizer) { State::Normalizer.instance([:bar]) }

      it 'normalizes data' do
        expect(state.normalize_data(normalizer).bare_state).to eq({ bar: :normalized, error: :error })
      end

      it 'copies meta' do
        expect(state.meta.trace).to eq([:foo])
      end
    end

    describe '::instance' do
      context "when data don't contain error" do
        let(:data) { { model: TestModel.new(5) } }

        context 'when validations are nil' do
          let(:validations) { nil }

          it "doesn't set error" do
            expect(state.bare_state[:error]).to be_nil
          end
        end

        context 'when validations pass' do
          let(:validations) { [proxy.validate(:model)] }

          it "doesn't set error" do
            expect(state.bare_state[:error]).to be_nil
          end
        end

        context 'when validations fail' do
          let(:data) { { model: TestModel.new(0) } }
          let(:validations) { failing_validations }

          it 'stores failure under error key' do
            expect(state.bare_state[:error]).to be_a(Validation::Result::Failure)
            expect(state.bare_state[:error].key).to eq(:model)
            expect(state.bare_state[:error].name).to eq(:model_is_valid)
          end
        end
      end

      context 'when data contain error' do
        let(:data) { { error: 'Error!!!', model: TestModel.new(nil) } }
        let(:validations) { failing_validations }

        context 'when invalid key is present' do
          it "doesn't alter data" do
            expect(state.bare_state[:error]).to eq('Error!!!')
          end
        end
      end
    end

    describe '::validate' do
      let(:validation) do
        Validation::Builder::Proxy
          .instance(Adapters::Validation::Generic, TestValidationCollection, name: :key_is_valid)
          .validate(:key) do |value|
          case value
          when :valid then true
          when :valid_with_detail then [true, :detail]
          when :invalid then false
          when :invalid_with_detail then [false, :detail]
          else raise 'Error in foreign code!'
          end
        end
      end

      context 'when validation returns true' do
        it 'returns original data' do
          expect(state_class.validate({ key: :valid }, [validation]))
            .to eq({ key: :valid })
        end
      end

      context 'when validation returns false' do
        it 'returns correctly populated failure object' do
          result = state_class.validate({ key: :invalid }, [validation])
          expect(result[:error]).to have_attributes(
            key: :key,
            name: :key_is_valid,
            data: nil
          )
        end
      end
    end
  end
end
