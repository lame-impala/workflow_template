# frozen_string_literal: true

require_relative '../../lib/workflow_template'
require_relative '../support/readme_helper'
require_relative '../support/rails_mockup'

module WorkflowTemplate
  module Readme
    RSpec.describe 'README: handling' do
      # rubocop:disable Security/Eval

      let(:outcome) { Outcome.new(final_state) }
      let(:final_state) do
        State.state_class(State::Adapter.fetch(:default))
             .initial(state_hash, :merge, [])
             .final
      end

      def use_result(result)
        result
      end

      context 'with basic approach' do
        def handle_error(error)
          error
        end

        let(:result) { eval(ReadmeHelper.specs[:basic_handling]) }

        context 'with ok result' do
          let(:state_hash) { { result: :ok } }

          it 'uses ok handler' do
            expect(result).to eq(:ok)
          end
        end

        context 'with error result' do
          let(:state_hash) { { result: :error } }

          it 'uses error handler' do
            expect(result).to eq(:error)
          end
        end
      end

      context 'with handler block' do
        context 'with simple handler block' do
          let(:result) { eval(ReadmeHelper.specs[:simple_handler_block]) }

          context 'with ok result' do
            let(:state_hash) { { result: :ok } }

            it 'runs ok handler' do
              expect(result).to eq(:ok)
            end
          end

          context 'with error result' do
            let(:state_hash) { { error: :error } }

            it 'runs error handler' do
              expect { result }.to raise_error(WorkflowTemplate::ExecutionError, 'error')
            end
          end
        end

        context 'with complete handler block' do
          def unauthorized!
            421
          end

          def not_found!
            404
          end

          def handle_error(*)
            500
          end

          let(:result) { eval(ReadmeHelper.specs[:complete_handler_block]) }

          context 'with ok result' do
            let(:state_hash) { { result: :ok } }

            it 'uses ok handler' do
              expect(result).to eq(:ok)
            end
          end

          context 'with specific error' do
            context 'with error as symbol' do
              let(:state_hash) { { error: :unauthorized } }

              it 'uses specific error handler' do
                expect(result).to eq(421)
              end
            end

            context 'with error as object' do
              let(:state_hash) { { error: ActiveRecord::RecordNotFound.new('Not found') } }

              it 'uses specific error handler' do
                expect(result).to eq(404)
              end
            end
          end

          context 'with generic error' do
            let(:state_hash) { { error: :error } }

            it 'uses error handler' do
              expect(result).to eq(500)
            end
          end
        end
      end

      describe 'unwrapping the outcome' do
        let(:state_hash) { { foo: 'FOO', bar: 'BAR', baz: 'BAZ', bax: 'BAX' } }

        it 'uses correctly implemented code snippet' do
          eval(ReadmeHelper.specs[:unwrapping_outcome])
          expect(@foo).to eq('FOO')
          expect([@bar, @bax]).to eq(%w[BAR BAX])
          expect(@result_hash).to eq(state_hash)
        end
      end
      # rubocop:enable Security/Eval
    end
  end
end
