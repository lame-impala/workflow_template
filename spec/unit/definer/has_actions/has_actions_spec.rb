# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/workflow_template/definer/has_actions'

module WorkflowTemplate
  module Definer
    RSpec.describe HasActions do
      let(:definer) do
        Class.new do
          extend HasActions
          extend HasActions::Nested::Unprepared
        end
      end

      describe '#prepend_action' do
        before { definer.apply(:old_action) }

        it 'prepends simple action to the collection' do
          expect do
            definer.prepend_action
                   .apply(:new_action, defaults: { value: 1 }, state: :update, validate: :value)
          end.to change { definer.actions.simple.map(&:name) }.from([:old_action]).to(%i[new_action old_action])
        end
      end

      describe '#append_action' do
        before { definer.apply(:old_action) }

        it 'appends simple action to the collection' do
          expect do
            definer.append_action
                   .apply(:new_action, defaults: { value: 1 }, state: :update, validate: :value)
          end.to change { definer.actions.simple.map(&:name) }.from([:old_action]).to(%i[old_action new_action])
        end
      end

      describe '#replace' do
        before { definer.apply(:old_action) }

        it 'appends simple action to the collection' do
          expect do
            definer.replace_action(:old_action)
                   .apply(:new_action, defaults: { value: 1 }, state: :update, validate: :value)
          end.to change { definer.actions.simple.map(&:name) }.from([:old_action]).to([:new_action])
        end
      end

      describe '#apply' do
        it 'adds simple action to the collection' do
          expect do
            definer.apply(:new_action, defaults: { value: 1 }, state: :update, validate: :value)
          end.to change { definer.actions.simple.length }.from(0).to(1)
        end
      end

      describe '#wrap_template' do
        it 'adds wrapper action to the collection' do
          expect do
            definer.wrap_template(:new_action, defaults: { value: 1 }, state: :update, validate: :value)
          end.to change { definer.actions.wrapper.length }.from(0).to(1)
        end
      end

      describe '#inside_action' do
        before do
          definer.apply(:nested_action, defaults: { value: 1 }, state: :update, validate: :value) do
            apply :old_action
          end
        end

        it 'modifies the nested action' do
          definer.inside_action(:nested_action) do
            apply(:new_action)
          end
          definer.freeze

          expected_description = [
            'nested_action defaults: { value: 1 }, validates: value, state: update',
            '  old_action',
            '  new_action'
          ]
          expect(definer.describe.format(level: 0)).to eq(expected_description)
        end
      end
    end
  end
end
