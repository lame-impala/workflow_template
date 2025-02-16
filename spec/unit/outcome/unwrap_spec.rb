# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/test_simple_workflow'
require_relative '../../../lib/workflow_template/outcome'
require_relative '../../../lib/workflow_template/state'

module WorkflowTemplate
  RSpec.describe Outcome do
    context 'result ok' do
      context 'with no option' do
        it 'returns whole result' do
          result = TestSimple.impl.perform({ valid: true, outcome: :ok }).unwrap
          expect(result).to eq({ model: :model, extra: :extra, valid: true, outcome: :ok })
        end
      end

      context 'with slice option' do
        it 'returns sliced array in correct order' do
          result = TestSimple.impl.perform({ valid: true, outcome: :ok }).unwrap(slice: %i[model bogus extra])
          expect(result).to eq([:model, nil, :extra])
          result = TestSimple.impl.perform({ valid: true, outcome: :ok }).handle do
            otherwise_unwrap(slice: %i[extra bogus model])
          end
          expect(result).to eq([:extra, nil, :model])
        end
      end

      context 'with fetch option' do
        it 'fetches single element' do
          result = TestSimple.impl.perform({ valid: true, outcome: :ok }).unwrap(fetch: :model)
          expect(result).to eq(:model)
        end
      end

      context 'with both slice and fetch option' do
        context 'when fetching element present in slice' do
          it 'fetches correct element' do
            result = TestSimple.impl.perform({ valid: true, outcome: :ok }).unwrap(slice: [:model], fetch: :model)
            expect(result).to eq(:model)
          end
        end

        context 'when fetching element absent from slice' do
          it 'fetches nil value' do
            result = TestSimple.impl.perform({ valid: true, outcome: :ok }).unwrap(slice: [:extra], fetch: :model)
            expect(result).to be_nil
          end
        end
      end
    end

    context 'result invalid' do
      it 'raises WorkflowTemplate::Validation::Error' do
        expect do
          TestSimple.impl.perform({ valid: true, outcome: :invalid }).unwrap(fetch: :model)
        end.to raise_error(Validation::Error, 'validation_failed: valid block validation')
      end
    end

    context 'result error as symbol' do
      it 'raises runtime error' do
        expect do
          TestSimple.impl.perform({ valid: true, outcome: :error }).unwrap(fetch: :model)
        end.to raise_error(ExecutionError, 'boo!')
      end
    end

    context 'result error as Exception' do
      it 'reraises the original error' do
        expect do
          TestSimple.impl.perform({ valid: true, outcome: :raise }).unwrap(fetch: :model)
        end.to raise_error(Error, 'BOO!')
      end
    end
  end
end
