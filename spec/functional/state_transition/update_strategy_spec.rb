# frozen_string_literal: true

require 'spec_helper'
require_relative '../../support/test_subclassing_workflow'

module WorkflowTemplate
  class UpdatingWorkflow < Workflow
    default_state_transition_strategy :update

    wrap_template :log

    apply :init
    and_then :build
    and_then :transaction do
      and_then :save
    end

    def log(logger:, **input, &block)
      logger.log('Enter workflow')
      result = block.call(**input)
      logger.log('Exit workflow')
      { logger: logger, **result }
    end

    def init(owner_id:, **attributes)
      owner = { id: owner_id }
      { owner: owner, **attributes }
    end

    def build(owner:, name:)
      model = { owner: owner, name: name, saved: nil }
      { model: model }
    end

    def transaction(model:, &block)
      block.call(model: model, txn_id: '123')
    end

    def save(model:, txn_id:)
      model = { **model, saved: txn_id }
      { model: model }
    end

    freeze
  end

  class UpdatingSubclass < UpdatingWorkflow
    freeze
  end

  RSpec.describe 'update transition strategy' do
    it 'updates inner state between calls' do
      logger = Logger.new
      UpdatingSubclass.impl.perform({ logger: logger, owner_id: 5, name: 'Foo' }).handle do
        ok do |model:, logger:|
          expect(model).to eq({ owner: { id: 5 }, name: 'Foo', saved: '123' })
          expect(logger.messages).to eq(['Enter workflow', 'Exit workflow'])
        end
        otherwise_raise
      end
    end
  end
end
