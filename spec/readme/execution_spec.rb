# frozen_string_literal: true

require_relative '../../lib/workflow_template'
require_relative '../support/test_logger'
require_relative '../support/rails_mockup'
require_relative '../support/readme_helper'

module WorkflowTemplate
  module Readme
    # rubocop:disable Security/Eval, RSpec/NoExpectationExample
    eval(ReadmeHelper.specs[:simple_declaration])
    eval(ReadmeHelper.specs[:mixed_strategy_declaration])
    eval(ReadmeHelper.specs[:normalize_output_declaration])
    eval(ReadmeHelper.specs[:impl_object_declaration])
    eval(ReadmeHelper.specs[:nested_actions_declaration])
    eval(ReadmeHelper.specs[:wrapper_actions_declaration])

    eval(ReadmeHelper.specs[:simple_implementation])

    class WrapperActionsWorkflowImpl
      eval(ReadmeHelper.specs[:logging_wrapper_action])

      def self.validate_model(model:, **)
        model == :invalid ? { error: :model_invalid } : nil
      end

      def self.transaction(input, &block)
        ActiveRecord::Base.connection.transaction do
          block.call(input)
        end
      end

      def self.update_model(**)
        { model: :updated }
      end

      def self.update_dependencies(**)
        nil
      end
    end

    RSpec.describe 'README: execution' do
      describe 'merge strategy workflow' do
        it 'performs all actions in order' do
          eval(ReadmeHelper.specs[:merge_strategy_execution])
        end
      end

      describe 'mixed strategy workflow' do
        it 'performs all actions in order' do
          eval(ReadmeHelper.specs[:mixed_strategy_execution])
        end
      end

      describe 'output normalizing workflow' do
        it 'performs all actions in order' do
          eval(ReadmeHelper.specs[:normalize_output_execution])
        end
      end

      context 'workflow with implicit implementation object' do
        it 'performs all actions in order' do
          eval(ReadmeHelper.specs[:impl_object_execution])
        end

        it 'transforms result using supplied adapter' do
          eval(ReadmeHelper.specs[:final_state_transformation])
        end
      end

      describe 'workflow with wrapper actions' do
        subject(:outcome) { WrapperActionsWorkflow.perform({ model: :valid }, WrapperActionsWorkflowImpl) }

        it 'performs nested actions' do
          expect(outcome.data).to eq({ model: :updated })
        end

        it 'performs wrapper action' do
          expect { outcome }.to change(Logger.messages, :length).by(2)
        end

        it 'performs nesting action' do
          expect { outcome }.to change(ActiveRecord::Base.connection, :transaction_id).by(1)
        end
      end

      describe 'workflow with nested actions' do
        subject(:outcome) { NestedActionsWorkflow.perform({ model: :valid }, WrapperActionsWorkflowImpl) }

        it 'performs nested actions' do
          expect(outcome.data).to eq({ model: :updated })
        end

        it 'performs wrapper action' do
          expect { outcome }.to change(Logger.messages, :length).by(2)
        end

        it 'performs nesting action' do
          expect { outcome }.to change(ActiveRecord::Base.connection, :transaction_id).by(1)
        end
      end
      # rubocop:enable Security/Eval, RSpec/NoExpectationExample
    end
  end
end
