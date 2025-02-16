# frozen_string_literal: true

require 'spec_helper'
require_relative '../support/test_subclassing_workflow'

module WorkflowTemplate
  RSpec.describe 'Workflow::perform' do
    context 'when invalid value supplied to input' do
      let(:ok_workflow) do
        Class.new(Workflow) do
          apply(:ok_action)

          def ok_action(**)
            { result: :ok }
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expected = "Invalid input, Hash expected, got '\"Bogus\"' (String)"
        expect do
          ok_workflow.impl.perform('Bogus')
        end.to raise_error(Fatal, expected)
      end
    end

    context 'when invalid value returned' do
      let(:faulty_workflow) do
        Class.new(Workflow) do
          apply(:bad_return)

          def bad_return(**)
            'Bogus'
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expected = "Invalid return from 'bad_return' action, nil or Hash expected, got '\"Bogus\"' (String)"
        expect do
          faulty_workflow.impl.perform({})
        end.to raise_error(Fatal, expected)
      end
    end

    context 'when non-symbolic key returned' do
      let(:faulty_workflow) do
        Class.new(Workflow) do
          apply(:bad_return)

          def bad_return(**)
            { 'Bogus' => 'value' }
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expected = "Invalid return from 'bad_return' action, symbolic keys expected, got '\"Bogus\"' (String)"
        expect do
          faulty_workflow.impl.perform({})
        end.to raise_error(Fatal, expected)
      end
    end

    context 'with fatal error raised' do
      let(:fatal_error_raised) do
        Class.new(Workflow) do
          apply :action

          def action(**)
            raise Fatal, 'BOO!!!'
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expect do
          fatal_error_raised.impl.perform({})
        end.to raise_error(Fatal::Detailed, "Fatal error in 'action': BOO!!!, input: {}")
      end
    end

    context 'with plain action unimplemented' do
      let(:plain_action_unimplemented) do
        Class.new(Workflow) do
          apply :implemented
          and_then :unimplemented
          and_then :never_reached

          def implemented(**)
            # NOOP
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expect { plain_action_unimplemented.impl.perform({}) }
          .to raise_error(Fatal::Unimplemented, "Unimplemented method: 'unimplemented'")
      end
    end

    context 'with wrapper action unimplemented' do
      let(:wrapper_action_unimplemented) do
        Class.new(Workflow) do
          apply :implemented
          and_then :unimplemented do
            :never_reached
          end
          and_then :never_reached

          def implemented(**)
            # NOOP
          end

          freeze
        end
      end

      it 'lets error fall through' do
        expect { wrapper_action_unimplemented.impl.perform({}) }
          .to raise_error(Fatal::Unimplemented, "Unimplemented method: 'unimplemented'")
      end
    end

    context 'with argument mismatch' do
      let(:argument_mismatch) do
        Class.new(Workflow) do
          apply :implemented

          def implemented(known: nil)
            self.class.implemented(known: known)
          end

          def self.implemented
            # NOOP
          end

          freeze
        end
      end

      context 'when error happens in invocation' do
        it 'lets error fall through' do
          expect { argument_mismatch.impl.perform({ unknown: :foo }) }
            .to raise_error(Fatal::ArgumentError, "Argument mismatch in 'implemented': unknown keyword: :unknown")
        end
      end

      context 'when error happens deeper in stack' do
        it 'captures error' do
          outcome = argument_mismatch.impl.perform({ known: :foo })
          expect(outcome.status).to eq(:error)
          expect(outcome.data[:error]).to be_a(ArgumentError)
        end
      end
    end
  end
end
