# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/workflow_template/workflow'
require_relative '../../../lib/workflow_template/adapters/state/dry_monads'
require_relative '../../support/test_validation_adapter'

module WorkflowTemplate
  module Adapters
    module State
      class DryMonadsSuperTest < Workflow
        include Dry::Monads[:result]

        state_adapter :dry_monads
        default_validation_adapter :test

        declare_validation(:not_eq_19).validate(:initial).to_not_eq(19)
        declare_validation(:not_eq_22).validate(:incremented).to_not_eq(22)
        declare_validation(:not_eq_150).validate(:final).to_not_eq(150)

        validate_input(:not_eq_19)

        wrap_template(:check_odd, validate: :not_eq_150)

        apply(:first, validate: :not_eq_22)

        def check_odd(initial:, raise:, **opts, &block)
          raise 'Check failed' if raise == :check_odd

          initial.odd? ? block.call(initial: initial, **opts) : Failure("#{initial} is not odd")
        end

        def first(initial:, raise:, **)
          raise 'First failed' if raise == :first

          initial < 100 ? Success({ incremented: initial + 1 }) : Failure("#{initial} too high")
        end

        freeze
      end

      class DryMonadsSubTest < DryMonadsSuperTest
        declare_validation(:not_eq_160).validate(:final).to_not_eq(160)
        declare_validation(:not_eq_170).validate(:final).to_not_eq(170)
        declare_validation(:not_eq_180).validate(:final).to_not_eq(180)

        and_then(:transaction, validate: :not_eq_160, defaults: { timeout: false }) do
          and_then(:second, validate: :not_eq_170)
          and_then(:side_effect)
        end

        validate_output(:not_eq_180)

        def transaction(raise:, timeout:, **opts, &block)
          return Failure('Timeout') if timeout

          block.call raise: raise, **opts
          raise 'Transaction error' if raise == :transaction
        end

        def second(incremented:, **)
          incremented > 20 ? Success({ final: incremented * 5 }) : Failure("#{incremented} too low")
        end

        def side_effect(raise:, **)
          raise 'Side effect raised' if raise == :side_effect
        end

        freeze
      end

      RSpec.describe DryMonads do
        let(:handled) do
          outcome.handle do
            ok do |final:, **|
              Success("OK: #{final}")
            end
            invalid do |error|
              Failure("INVALID: #{error.message}")
            end
            error('Timeout') do |error|
              Failure("TIMEOUT: #{error}")
            end
            otherwise do |error|
              Failure("OTHERWISE: #{error}")
            end
          end
        end
        let(:outcome) { DryMonadsSubTest.impl.perform({ initial: initial, raise: raise, **opts }) }
        let(:initial) { 99 }
        let(:raise) { nil }
        let(:opts) { {} }

        context 'when action is successful' do
          it 'returns success' do
            expect(outcome.to_result(fetch: :final).value!).to eq(500)
          end

          context 'when adapter is supplied' do
            context 'when target result is the same as wrapped state' do
              it 'returns canonical result' do
                expect(outcome.to_result(:dry_monads).value!)
                  .to eq(initial: 99, raise: nil, incremented: 100, final: 500)
                expect(outcome.to_result(:dry_monads, fetch: :final).value!)
                  .to eq(500)
                expect(outcome.to_result(:dry_monads, slice: %i[initial final]).value!)
                  .to eq([99, 500])
              end
            end

            context 'when target result is different from wrapped state' do
              it 'rewraps result' do
                expect(outcome.to_result(:default)).to eq({ initial: 99, raise: nil, incremented: 100, final: 500 })
                expect(outcome.to_result(:default, fetch: :final)).to eq(500)
                expect(outcome.to_result(:default, slice: %i[initial final])).to eq([99, 500])
              end
            end
          end

          it 'runs ok handler' do
            expect(handled.value!).to eq('OK: 500')
          end
        end

        context 'when input validation fails' do
          let(:initial) { 19 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 19')
          end

          it 'runs validation failure handler' do
            expect(handled.failure).to eq('INVALID: Value supposed not to equal 19')
          end
        end

        context 'when wrapper action fails' do
          let(:initial) { 18 }

          it 'returns failure' do
            expect(outcome.to_result.failure).to eq('18 is not odd')
          end

          context 'when adapter is supplied' do
            context 'when target result is the same as wrapped state' do
              it 'returns canonical result' do
                expect(outcome.to_result(:dry_monads).failure)
                  .to eq('18 is not odd')
              end
            end

            context 'when target result is different from wrapped state' do
              it 'rewraps result' do
                expect(outcome.to_result(:default)).to eq({ error: '18 is not odd' })
              end
            end
          end
        end

        context 'when wrapper validation fails' do
          let(:initial) { 29 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 150')
          end
        end

        context 'when wrapper action raises' do
          let(:raise) { :check_odd }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Check failed')
          end
        end

        context 'when simple action fails' do
          let(:initial) { 101 }

          it 'returns failure' do
            expect(outcome.to_result.failure).to eq('101 too high')
          end

          it 'runs otherwise handler' do
            expect(handled.failure).to eq('OTHERWISE: 101 too high')
          end
        end

        context 'when simple action validation fails' do
          let(:initial) { 21 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 22')
          end
        end

        context 'when simple action raises' do
          let(:raise) { :first }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('First failed')
          end
        end

        context 'when nesting action validation fails' do
          let(:initial) { 31 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 160')
          end
        end

        context 'when nesting action fails' do
          let(:opts) { { timeout: true } }

          it 'returns failure' do
            expect(outcome.to_result.failure).to eq('Timeout')
          end

          it 'runs specific error handler' do
            expect(handled.failure).to eq('TIMEOUT: Timeout')
          end
        end

        context 'when nesting action raises' do
          let(:raise) { :transaction }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Transaction error')
          end
        end

        context 'when nested action fails' do
          let(:initial) { 33 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 170')
          end
        end

        context 'when nested action raises' do
          let(:raise) { :side_effect }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Side effect raised')
          end
        end

        context 'when output validation fails' do
          let(:initial) { 35 }

          it 'returns failure' do
            expect(outcome.to_result.failure.message).to eq('Value supposed not to equal 180')
          end
        end
      end
    end
  end
end
