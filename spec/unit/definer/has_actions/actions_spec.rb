# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/workflow_template/definer/has_actions/actions'
require_relative '../../../../lib/workflow_template/definer/has_actions/position'
require_relative '../../../../lib/workflow_template/action'

module WorkflowTemplate
  module Definer
    module HasActions
      RSpec.describe Actions::Unprepared do
        let(:unprepared) do
          described_class.instance.tap do |actions|
            actions.add_simple(Action::Simple::Unprepared.new(:second), Position.instance(:after, nil))
            actions.add_simple(Action::Simple::Unprepared.new(:first), Position.instance(:before, :second))
            actions.add_wrapper(Action::Simple::Unprepared.new(:inner))
            actions.add_wrapper(Action::Simple::Unprepared.new(:outer))
          end
        end

        describe '#prepared' do
          it 'orders simple actions' do
            expect(unprepared.prepared.simple.map(&:name)).to eq(%i[first second])
          end

          it 'maintains reversed order of insertion for wrapper actions' do
            expect(unprepared.prepared.wrapper.map(&:name)).to eq(%i[outer inner])
          end
        end
      end

      RSpec.describe Actions::Prepared do
        let(:simple) { [Action::Simple::Unprepared.new(:second)] }
        let(:wrapper) { %i[outer1 inner1].map { instance_double(Action::Simple::Unprepared, name: _1) } }
        let(:prepared) { described_class.new(simple: simple, wrapper: wrapper) }

        let(:unprepared) do
          Actions::Unprepared.instance.tap do |actions|
            actions.add_simple(Action::Simple::Unprepared.new(:third), Position.instance(:after, :second))
            actions.add_simple(Action::Simple::Unprepared.new(:first), Position.instance(:before, :second))
            actions.add_wrapper(instance_double(Action::Wrapper::Unprepared, name: :inner2))
            actions.add_wrapper(instance_double(Action::Wrapper::Unprepared, name: :outer2))
          end
        end

        describe '#merge' do
          it 'orders new and existing simple actions' do
            expect(prepared.merge(unprepared).simple.map(&:name)).to eq(%i[first second third])
          end

          it 'prepends new wrapper actions to existing' do
            expect(prepared.merge(unprepared).wrapper.map(&:name)).to eq(%i[outer2 inner2 outer1 inner1])
          end
        end

        describe '#next_wrapper_action' do
          let(:simple) { [Action::Simple::Unprepared.new(:simple)] }

          let(:prepared) do
            described_class.new(simple: simple, wrapper: wrapper)
          end

          context 'when wrapper action present' do
            let(:wrapper) { [Action::Wrapper::Unprepared.new(:first), Action::Wrapper::Unprepared.new(:second)] }

            it 'returns first wrapper action and the updated container' do
              action, container = prepared.next_wrapper_action
              expect(action.name).to eq(:first)
              expect(container.wrapper.map(&:name)).to eq([:second])
              expect(container.simple.map(&:name)).to eq([:simple])
            end
          end

          context 'when wrapper actions empty' do
            let(:wrapper) { [] }

            it 'returns nil and an unmodified container' do
              action, container = prepared.next_wrapper_action
              expect(action).to be_nil
              expect(container.wrapper).to eq([])
              expect(container.simple.map(&:name)).to eq([:simple])
            end
          end
        end
      end
    end
  end
end
