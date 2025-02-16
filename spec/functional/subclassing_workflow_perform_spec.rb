# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_subclassing_workflow'

module WorkflowTemplate
  RSpec.describe 'Workflow::validations.declarations' do
    it 'returns superclass validations merged with subclass validations' do
      validations = TestDesc.send(:validations).declarations
      expect(validations.keys).to contain_exactly(:array_present, :last_in_not_nil, :extra)
    end
  end

  RSpec.describe 'Workflow::perform' do
    let(:implementation) { TestDesc.new }

    it 'writes wrapper block output into result' do
      Logger.reset
      TestDesc.perform({ last_in: :null }, implementation).handle do |_outcome|
        ok do |base:, desc:, last_in:, last_out:, **|
          expect(base).to eq(:ok)
          expect(desc).to eq(:ok)
          expect(last_in).to eq(:base)
          expect(last_out).to eq(:desc)
        end
        otherwise_raise
      end
    end

    it 'runs wrapper blocks in order' do
      Logger.reset
      outcome = TestDesc.perform({ last_in: :null }, implementation, trace: true)
      trace = outcome.meta.trace
      expect(trace).to eq(%i[noop_desc log_desc noop_base log_base first second third fourth fifth sixth])

      outcome.handle do
        ok do |array:, **|
          expect(array).to eq([1, 2, 3, 4, 5, 6])
        end
        otherwise_raise
      end

      exp = ['start desc', 'start base', 'end base', 'end desc']
      expect(Logger.messages).to eq(exp)
    end

    context 'when raised error is captured in base wrapper block' do
      let(:result) do
        Logger.reset
        TestDesc.perform({ last_in: :null, outcome: :raise_base }, implementation, trace: true)
      end
      let(:data) { result.data }
      let(:trace) { result.meta.trace }

      it 'traces actions' do
        expect(trace).to eq(%i[noop_desc log_desc noop_base log_base first second third])
      end

      it 'transforms input in base' do
        expect(data[:last_in]).to eq(:base)
      end

      it 'does not finish the base wrapper block' do
        expect(data[:base]).to be_nil
      end

      it 'finishes the descendant wrapper block' do
        expect(data[:desc]).to eq(:ok)
        expect(data[:last_out]).to eq(:desc)
      end

      it 'captures the error' do
        expect(data[:error]).to eq(:base)
      end

      it 'runs ensure blocks in wrapper actions' do
        exp = ['start desc', 'start base', 'end base', 'end desc']
        expect(Logger.messages).to eq(exp)
      end
    end

    context 'when raised error is captured in desc wrapper block' do
      let(:retval) do
        Logger.reset
        TestDesc.perform({ last_in: :null, outcome: :raise_desc }, implementation).handle do
          error { |opts| opts }
          otherwise_raise
        end
      end

      it 'transforms input in base' do
        expect(retval[:last_in]).to eq(:base)
      end

      it 'finishes the base wrapper block' do
        expect(retval[:base]).to eq(:ok)
      end

      it 'does not finish the descendant wrapper block' do
        expect(retval[:desc]).to be_nil
        expect(retval[:last_out]).to eq(:base)
      end

      it 'captures the error' do
        expect(retval[:error]).to eq(:desc)
      end

      it 'runs ensure blocks in wrapper actions' do
        exp = ['start desc', 'start base', 'end base', 'end desc']
        expect(Logger.messages).to eq(exp)
      end
    end

    context 'when error is returned' do
      let(:retval) do
        Logger.reset
        TestDesc.perform({ last_in: :null, outcome: :return_error }, implementation).handle do
          error { |opts| opts }
          otherwise_raise
        end
      end

      it 'transforms input in base' do
        expect(retval[:last_in]).to eq(:base)
      end

      it 'does finish the base wrapper block' do
        expect(retval[:base]).to eq(:ok)
      end

      it 'finishes the descendant wrapper block' do
        expect(retval[:desc]).to eq(:ok)
        expect(retval[:last_out]).to eq(:desc)
      end

      it 'returns the error' do
        expect(retval[:error]).to eq(:returned_from_third)
      end

      it 'retains the intermediate result' do
        expect(retval[:array]).to eq([1, 2])
      end

      it 'runs ensure blocks in wrapper actions' do
        exp = ['start desc', 'start base', 'end base', 'end desc']
        expect(Logger.messages).to eq(exp)
      end
    end

    it 'performs inherited and own actions in correct order' do
      Logger.reset
      TestDesc.perform({ last_in: :null }, implementation).handle do
        ok do |array:, **|
          expect(array).to eq([1, 2, 3, 4, 5, 6])
        end
        otherwise_raise
      end
    end
  end
end
