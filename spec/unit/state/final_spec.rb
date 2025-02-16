# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../support/test_model'
require_relative '../../../lib/workflow_template/adapters/validation/generic'
require_relative '../../../lib/workflow_template/validation/builder/proxy'
require_relative '../../../lib/workflow_template/state'
require_relative '../../../lib/workflow_template/state/adapter'
require_relative '../../../lib/workflow_template/adapters/state/default'
require_relative '../../../lib/workflow_template/adapters/state/dry_monads'

module WorkflowTemplate
  module State
    RSpec.describe Final do
      subject(:state_class) { State.state_class(State::Adapter.fetch(:default)) }

      let(:proxy) do
        WorkflowTemplate::Validation::Builder::Proxy
          .instance(Adapters::Validation::ActiveModel, TestValidationCollection)
      end

      let(:failing_validation) do
        proxy.named(:model_is_valid).validate(:model)
      end
      let(:failing_validations) { [failing_validation] }
      let(:validations) { [] }
      let(:state) do
        state_class.initial(data, :update, validations).final
      end

      describe 'unwrapping data' do
        let(:data) { { foo: 'FOO', bar: 'BAR', bax: 'BAX' } }

        describe '#to_result' do
          context 'without error' do
            context 'with default adapter' do
              it 'returns data as hash' do
                expect(state.to_result).to eq(data)
              end
            end

            context 'when adapter is supplied' do
              context 'when target result is the same as wrapped state' do
                it 'returns canonical result' do
                  expect(state.to_result(:default)).to eq(data)
                  expect(state.to_result(:default, fetch: :foo)).to eq('FOO')
                  expect(state.to_result(:default, slice: %i[bar bax])).to eq(%w[BAR BAX])
                end
              end

              context 'when target result is different from wrapped state' do
                it 'rewraps result' do
                  expect(state.to_result(:dry_monads).value!).to eq(data)
                  expect(state.to_result(:dry_monads, fetch: :foo).value!).to eq('FOO')
                  expect(state.to_result(:dry_monads, slice: %i[bar bax]).value!).to eq(%w[BAR BAX])
                end
              end
            end
          end

          context 'with error' do
            let(:data) { super().merge(error: 'ERROR') }

            it 'returns data as hash' do
              expect(state.to_result).to eq(data)
            end

            context 'when adapter is supplied' do
              context 'when target result is the same as wrapped state' do
                it 'returns canonical result' do
                  expect(state.to_result(:default)).to eq(data)
                end
              end

              context 'when target result is different from wrapped state' do
                it 'rewraps result' do
                  expect(state.to_result(:dry_monads).failure).to eq('ERROR')
                end
              end
            end
          end
        end

        describe '#unwrap' do
          context 'with no options' do
            it 'returns all data' do
              expect(state.unwrap(slice: nil, fetch: nil)).to eq(data)
            end
          end

          context 'with slice option' do
            it 'returns values under required keys' do
              expect(state.unwrap(slice: %i[foo bar], fetch: nil)).to eq(%w[FOO BAR])
            end
          end

          context 'with fetch option' do
            it 'returns value under required key' do
              expect(state.unwrap(slice: nil, fetch: :foo)).to eq('FOO')
            end
          end

          context 'with fetch and slice option' do
            it 'returns value under required key' do
              # This combination of options makes no practical sense
              # but we need to be able to handle it anyway
              expect(state.unwrap(slice: %i[foo bar], fetch: :foo)).to eq('FOO')
            end
          end
        end

        describe '#fetch' do
          it 'returns value under required key' do
            expect(state.fetch(:foo)).to eq('FOO')
          end
        end

        describe '#slice' do
          it 'returnss values under required keys' do
            expect(state.slice(:foo, :bar)).to eq(%w[FOO BAR])
          end
        end
      end

      describe '#status' do
        context 'when error is not set' do
          let(:data) { { foo: 'FOO' } }

          it 'is not error' do
            expect(state).not_to be_error
          end

          it 'has :ok status' do
            expect(state.status).to eq(:ok)
          end
        end

        context 'when error is a symbol' do
          let(:data) { { error: :error } }

          it 'is not error' do
            expect(state).to be_error
          end

          it 'has :error status' do
            expect(state.status).to eq(:error)
          end
        end
      end
    end
  end
end
