# frozen_string_literal: true

require 'dry/validation'

require_relative '../../lib/workflow_template'
require_relative '../support/readme_helper'
require_relative '../support/test_model'
require_relative '../support/test_user'

module WorkflowTemplate
  module Readme
    # rubocop:disable Security/Eval

    eval(ReadmeHelper.specs[:validation_declaration])

    class Contract < Dry::Validation::Contract
      params do
        required(:value).value(:integer)
        required(:user)
      end
    end

    eval(ReadmeHelper.specs[:multiple_validation_declaration])

    class ValidatingWorkflowImplementation
      def self.authorize(user:, **)
        user.can?(:do_stuff) ? nil : { error: :unauthorized }
      end

      def self.populate(value:, **)
        { model: TestModel.new(value) }
      end

      def self.save(model:, **)
        { result: model.save! }
      end
    end

    RSpec.describe 'README: validation' do
      def use_result(value)
        "OK: #{value}"
      end

      def handle_invalid(value)
        "INVALID: #{value.failure.message}"
      end

      def handle_error(value)
        "ERROR: #{value}"
      end

      context 'with validating workflow' do
        let(:outcome) { ValidatingWorkflow.perform(input, ValidatingWorkflowImplementation) }
        let(:input) { { user: TestUser.new([:do_stuff]), value: -1 } }

        it 'performs validation' do
          expect(outcome.data[:error].failure.code)
            .to eq(:workflow_template_test_model_invalid)
        end

        context 'with handling block' do
          let(:result) { eval(ReadmeHelper.specs[:invalid_handler_block]) }

          context 'with ok result' do
            let(:input) { { user: TestUser.new([:do_stuff]), value: 1 } }

            it 'runs ok handler' do
              expect(result).to eq('OK: true')
            end
          end

          context 'with invalid result' do
            let(:input) { { user: TestUser.new([:do_stuff]), value: -1 } }

            it 'runs invalid handler' do
              expect(result).to eq('INVALID: Value must be greater than 0')
            end
          end

          context 'with error result' do
            let(:input) { { user: TestUser.new([]), value: 1 } }

            it 'runs error handler' do
              expect(result).to eq('ERROR: unauthorized')
            end
          end
        end
      end

      context 'with multiple validation workflow' do
        let(:outcome) { MultipleValidationWorkflow.perform(input, ValidatingWorkflowImplementation) }

        context 'when contract validation fails' do
          let(:input) { { value: :foo } }

          it 'returns error' do
            expect(outcome.data[:error].failure.data.errors.to_h)
              .to eq({ user: ['is missing'], value: ['must be an integer'] })
          end
        end

        context 'when authorization validation fails' do
          let(:input) { { user: TestUser.new([]), value: 1 } }

          it 'returns error' do
            expect(outcome.data[:error].failure.data)
              .to eq(:unauthorized)
          end
        end

        context 'when model validation fails' do
          let(:input) { { user: TestUser.new([:do_stuff]), value: -1 } }

          it 'returns error' do
            expect(outcome.data[:error].failure.code)
              .to eq(:workflow_template_test_model_invalid)
          end
        end
      end
    end
    # rubocop:enable Security/Eval
  end
end
