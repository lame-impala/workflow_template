# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_subclassing_workflow'

module WorkflowTemplate
  RSpec.describe Workflow::ModuleMethods do
    context 'subclassing workflow' do
      it 'inherits existing actions and inserts its own' do
        simple_actions = TestDesc.actions.simple
        expect(simple_actions.length).to eq(6)
        expect(simple_actions).to be_frozen
        expect(simple_actions.map(&:name)).to eq(%i[first second third fourth fifth sixth])
      end

      it 'inherits existing wrapper blocks and inserts its own' do
        wrapper_actions = TestDesc.actions.wrapper
        expect(wrapper_actions.length).to eq(4)
        expect(wrapper_actions).to be_frozen
        expect(wrapper_actions.map(&:name)).to eq(%i[noop_desc log_desc noop_base log_base])
      end

      it 'inherits existing validations and inserts its own' do
        validations = TestDesc.send(:validations).declarations
        expect(validations.length).to eq(3)
        expect(validations).to be_frozen
      end
    end
  end
end
