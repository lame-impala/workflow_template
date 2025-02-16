# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/workflow_template/state/normalizer'

module WorkflowTemplate
  RSpec.describe State::Normalizer do
    let(:ok_state) { { input: 'A', result: 'B' } }
    let(:error_state) { { input: 'A', result: 'B', error: 'E' } }
    let(:normalizer) { described_class.instance(%i[result halted]) }
    let(:null_normalizer) { described_class.instance }

    describe '#normalize' do
      context 'with null normalizer' do
        it 'returns the original data' do
          expect(null_normalizer.normalize(ok_state)).to eq(ok_state)
        end
      end

      context 'with keys defined' do
        it 'returns all defined keys' do
          expect(normalizer.normalize(ok_state)).to eq({ result: 'B', halted: nil })
        end
      end
    end
  end
end
