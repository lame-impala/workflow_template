# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/workflow_template/workflow'
require_relative '../support/test_subclassing_workflow'

module WorkflowTemplate
  RSpec.describe Workflow do
    let(:implementation) { TestDesc.new }

    it 'recovers if wrapper action raises before yield' do
      outcome = TestDesc.perform({ last_in: :null, raise_in_base_logger: :before }, implementation)
      expect(outcome.data[:base]).to be_nil
      expect(outcome.data[:desc]).to eq(:ok)
      expect(outcome.data[:last_in]).to eq(:desc)
      expect(outcome.data[:last_out]).to eq(:desc)
      expect(outcome.data[:array]).to be_nil
      expect(outcome.data[:error].message).to eq('Raised in Base logger before')
    end

    it 'recovers if wrapper action raises after yield' do
      outcome = TestDesc.perform({ last_in: :null, raise_in_base_logger: :after }, implementation)
      expect(outcome.data[:base]).to be_nil
      expect(outcome.data[:desc]).to eq(:ok)
      expect(outcome.data[:last_in]).to eq(:base)
      expect(outcome.data[:last_out]).to eq(:desc)
      expect(outcome.data[:array]).to eq([1, 2, 3, 4, 5, 6])
      expect(outcome.data[:error].message).to eq('Raised in Base logger after')
    end
  end
end
