# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class NormalizingWorkflow < Workflow
    apply :first
    and_then :second

    def first(input:, **)
      if input == :halt
        { result: 'first', halted: true }
      else
        { result: 'first' }
      end
    end

    def second(input:, **)
      case input
      when :error then { error: :error }
      when :raise then raise 'Error!'
      else { result: 'second' }
      end
    end

    normalize_output :result, :extra
    freeze
  end

  RSpec.describe Workflow do
    let(:outcome) { NormalizingWorkflow.impl.perform(input) }

    context 'with ok result' do
      context 'with all declared keys present' do
        let(:input) { { input: :ok, extra: 'EXTRA' } }

        it 'returns all declared keys in normalized output' do
          expect(outcome.data).to eq({ result: 'second', extra: 'EXTRA' })
        end
      end

      context 'with declared key missing' do
        let(:input) { { input: :ok } }

        it 'sets missing key to nil in normalized output' do
          expect(outcome.data).to eq({ result: 'second', extra: nil })
        end
      end
    end

    context 'when halted' do
      context 'with all declared keys present' do
        let(:input) { { input: :halt, extra: 'EXTRA' } }

        it 'returns all declared keys in normalized output' do
          expect(outcome.data).to eq({ result: 'first', extra: 'EXTRA' })
        end
      end

      context 'with declared key missing' do
        let(:input) { { input: :halt } }

        it 'sets missing key to nil in normalized output' do
          expect(outcome.data).to eq({ result: 'first', extra: nil })
        end
      end
    end

    context 'when error returned' do
      context 'with all declared keys present' do
        let(:input) { { input: :error, extra: 'EXTRA' } }

        it 'returns all declared keys and error in normalized output' do
          expect(outcome.data).to eq({ result: 'first', extra: 'EXTRA', error: :error })
        end
      end

      context 'with declared key missing' do
        let(:input) { { input: :raise } }

        it 'sets missing key to nil in normalized output' do
          expect(outcome.data).to match(hash_including(result: 'first', extra: nil, error: RuntimeError))
        end
      end
    end
  end
end
