# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../support/test_model'
require_relative '../../../lib/workflow_template/outcome/handler'
require_relative '../../../lib/workflow_template/state'
require_relative '../../../lib/workflow_template/adapters/state/default'
require_relative '../../../lib/workflow_template/state/adapter'
require_relative '../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  class Outcome
    # rubocop:disable Lint/EmptyBlock
    RSpec.describe Handler do
      let(:state_class) { State.state_class(Adapters::State::Default) }

      context 'with OK result' do
        let(:ok_result) { State::Final.new({}, [], state_class) }

        it 'has initial retval nil' do
          handler = described_class.new(ok_result)
          expect(handler.retval).to be_nil
        end

        it 'sets correct retval' do
          handler = described_class.new(ok_result).handle_status(:ok) { 'retval' }
          expect(handler.retval).to eq('retval')
        end

        it 'is unhandled if result status unhandled' do
          handler = described_class.new(ok_result)
          expect(handler.unhandled?(:ok)).to be(true)
        end

        it 'is not unhandled if result status handled' do
          handler = described_class.new(ok_result).handle_status(:ok) {}
          expect(handler.unhandled?(:ok)).to be(false)
        end

        it "doesn't report default missing if statuses all handled" do
          handler = described_class.new(ok_result).handle_status(:ok) {}.handle_status(:error) {}
          expect(handler.default_missing).to be_empty
        end

        it 'reports unhandled status if default is not supplied' do
          handler = described_class.new(ok_result).handle_status(:ok) do
          end.handle_status(:error, matcher: Symbol)
          expect(handler.default_missing).to contain_exactly(:error)
        end

        context 'when unreachable handler is supplied' do
          context 'when default handler is supplied twice' do
            it 'raises error' do
              expect do
                described_class.new(ok_result).handle_status(:ok) {}.handle_status(:ok) {}
              end.to raise_error(Error, "Handler for 'ok' unexpected")
            end
          end

          context 'when matching handler is supplied after the default' do
            it 'raises error' do
              expect do
                described_class
                  .new(ok_result)
                  .handle_status(:error) {}
                  .handle_status(:error, matcher: Symbol) {}
              end.to raise_error(Error, "Handler for 'error' unexpected")
            end
          end
        end

        context 'when catchall handler is supplied' do
          context 'when status is handled before catchall handler' do
            let(:handler) do
              described_class.new(ok_result).handle_status(:ok) { 'ok retval' }.otherwise { 'otherwise retval' }
            end

            it 'keeps return value from handled step' do
              expect(handler.retval).to eq('ok retval')
            end

            it 'marks all statuses as having default' do
              expect(handler.default_missing).to be_empty
            end
          end

          context 'then status is unhandled before catchall handler' do
            let(:handler) do
              described_class.new(ok_result)
                             .handle_status(:error) { 'ok retval' }
                             .otherwise { 'otherwise retval' }
            end

            it 'uses return value from catchall step' do
              expect(handler.retval).to eq('otherwise retval')
            end

            it 'marks all statuses as having default' do
              expect(handler.default_missing).to be_empty
            end

            it 'marks result status as handled' do
              expect(handler.unhandled?(:ok)).to be(false)
            end
          end
        end
      end

      context 'with error result' do
        let(:error_result) { State::Final.new({ error: error }, [], state_class) }
        let(:retval) do
          described_class.new(error_result)
                         .handle_status(:error, matcher: :specific_error) { 'specific handler' }
                         .handle_status(:error, matcher: Symbol) { 'type matching handler' }
                         .handle_status(:error) { 'default handler' }
                         .retval
        end

        context 'with error matched by specific handler' do
          let(:error) { :specific_error }

          it 'runs matching handler' do
            expect(retval).to eq('specific handler')
          end
        end

        context 'with error matched by type matching handler' do
          let(:error) { :type_matching_error }

          it 'runs matching handler' do
            expect(retval).to eq('type matching handler')
          end
        end

        context 'with non matching error' do
          let(:error) { 'Non matching error' }

          it 'runs default handler' do
            expect(retval).to eq('default handler')
          end
        end
      end

      describe '#otherwise_unwrap' do
        context 'with ok result' do
          let(:result) do
            State.state_class(State::Adapter.fetch(:default))
                 .initial({ foo: 'FOO', bar: 'BAR', bax: 'BAX' }, :update, nil)
                 .final
          end

          context 'when status handled with specific handler' do
            let(:handler) { described_class.new(result).handle_status(:ok) { 'ok retval' }.otherwise_unwrap }

            it 'returns value from specific handler' do
              expect(handler.retval).to eq('ok retval')
            end

            it 'marks all statuses as having default' do
              expect(handler.default_missing?).to be(false)
            end
          end

          context 'when status unhandled' do
            context 'when neither slice nor fetch supplied' do
              let(:handler) { described_class.new(result).otherwise_unwrap }

              it 'returns complete data hash' do
                expect(handler.retval).to eq({ foo: 'FOO', bar: 'BAR', bax: 'BAX' })
              end

              it 'marks all statuses as having default' do
                expect(handler.default_missing?).to be(false)
              end

              it 'marks ok status as handled' do
                expect(handler.unhandled?(:ok)).to be(false)
              end
            end

            context 'when slice supplied' do
              let(:handler) { described_class.new(result).otherwise_unwrap(slice: %i[bax foo]) }

              it 'slices specified keys' do
                expect(handler.retval).to eq(%w[BAX FOO])
              end
            end

            context 'when fetch supplied' do
              let(:handler) { described_class.new(result).otherwise_unwrap(fetch: :bar) }

              it 'fetches specified key' do
                expect(handler.retval).to eq('BAR')
              end
            end
          end
        end

        context 'with invalid result' do
          let(:proxy) do
            Validation::Builder::Proxy
              .instance(Adapters::Validation::ActiveModel, TestValidationCollection)
          end
          let(:validations) { [proxy.validate(:model)] }
          let(:result) do
            State.state_class(State::Adapter.fetch(:default))
                 .initial({ model: TestModel.new(-5) }, :update, validations)
                 .final
          end

          context 'when status handled with specific handler' do
            let(:handler) do
              described_class
                .new(result)
                .handle_status(:error, matcher: Validation::Result::Failure) { 'model invalid!' }
                .otherwise_unwrap
            end

            it 'returns value from specific handler' do
              expect(handler.retval).to eq('model invalid!')
            end

            it 'marks all statuses as having default' do
              expect(handler.default_missing?).to be(false)
            end

            it 'marks error status as handled' do
              expect(handler.unhandled?(:error)).to be(false)
            end
          end

          context 'when status unhandled' do
            it 'raises error' do
              expect do
                described_class.new(result).otherwise_unwrap
              end.to raise_error(Validation::Error, 'workflow_template_test_model_invalid: model model to be valid')
            end
          end
        end

        context 'with error result' do
          let(:result) do
            State.state_class(State::Adapter.fetch(:default))
                 .initial({ foo: 'FOO', bar: 'BAR', error: error }, :update, nil)
                 .final
          end
          let(:handler) do
            described_class.new(result)
                           .handle_status(:error, matcher: :specific) { 'specific error retval' }
                           .otherwise_unwrap
          end

          context 'when status handled with specific handler' do
            let(:error) { :specific }

            it 'returns value from specific handler' do
              expect(handler.retval).to eq('specific error retval')
            end

            it 'marks all statuses as having default' do
              expect(handler.default_missing?).to be(false)
            end
          end

          context 'when status unhandled' do
            let(:error) { :general }

            it 'raises error' do
              expect { described_class.new(result).otherwise_unwrap }.to raise_error(ExecutionError, 'general')
            end
          end
        end
      end
    end
    # rubocop:enable Lint/EmptyBlock
  end
end
