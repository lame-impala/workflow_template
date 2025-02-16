# frozen_string_literal: true

require_relative '../../lib/workflow_template'
require_relative '../support/readme_helper'
require_relative '../support/test_logger'

module WorkflowTemplate
  module Readme
    # rubocop:disable Security/Eval, RSpec/NoExpectationExample
    class LoggingWorkflow < Workflow
      LOGGER = Logger.new

      eval(ReadmeHelper.specs[:action_with_default])

      def log_inputs(logger:)
        logger.log('Log message')
      end

      freeze
    end

    eval(ReadmeHelper.specs[:simple_action_redeclaration])
    eval(ReadmeHelper.specs[:wrapper_action_redeclaration])
    eval(ReadmeHelper.specs[:dry_monads_workflow])

    RSpec.describe 'README: declaration' do
      describe 'action declaration with default' do
        it 'uses correctly implemented code snippet' do
          expect { LoggingWorkflow.impl.perform({}) }
            .to change(LoggingWorkflow::LOGGER.messages, :length).by(1)
        end
      end

      describe 'redeclaring simple action' do
        let(:expected_description) do
          <<~DESC
            state: merge

            new_first
            second
            third
            fourth
          DESC
        end

        it 'uses correctly implemented code snippet' do
          expect(SimpleSubclass.describe).to eq(expected_description)
        end
      end

      describe 'redeclaring nested action' do
        it 'uses correctly implemented code snippet' do
          eval(ReadmeHelper.specs[:wrapper_action_description])
        end
      end

      describe 'dry monads workflow' do
        let(:outcome) { DryMonadsWorkflow.impl.perform({ input: 1 }) }

        it 'is correctly declared' do
          expect(outcome.fetch(:output)).to eq(2)
        end

        it 'uses correctly implemented code snippet' do
          eval(ReadmeHelper.specs[:dry_monads_outcome])
        end
      end
    end
    # rubocop:enable Security/Eval, RSpec/NoExpectationExample
  end
end
