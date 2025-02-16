# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/workflow_template/action'
require_relative '../../lib/workflow_template/definer/has_actions/position'

module WorkflowTemplate
  module Definer
    module HasActions
      RSpec.describe Position do
        def get_actions(*names)
          names.map do |name|
            Action.instance(name, :simple)
          end
        end

        context 'with no reference' do
          context 'with position as :before' do
            it 'places action before all' do
              actions = get_actions(:second, :third, :fourth)
              first = Action.instance(:first, :simple)
              position = described_class.instance(:before, nil)
              added = position.apply_onto(actions, first)
              expect(added.map(&:name)).to eq(%i[first second third fourth])
            end
          end

          context 'with position as :after' do
            it 'places action after all' do
              actions = get_actions(:first, :second, :third)
              fourth = Action.instance(:fourth, :simple)
              position = described_class.instance(:after, nil)
              added = position.apply_onto(actions, fourth)
              expect(added.map(&:name)).to eq(%i[first second third fourth])
            end
          end
        end

        context 'with reference' do
          context 'with position as :before' do
            context 'when reference is the first action' do
              it 'places action at the begining' do
                actions = get_actions(:second, :third, :fourth)
                first = Action.instance(:first, :simple)
                position = described_class.instance(:before, :second)
                added = position.apply_onto(actions, first)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end

            context 'when reference is an action in the middle' do
              it 'places action before the reference' do
                actions = get_actions(:first, :third, :fourth)
                second = Action.instance(:second, :simple)
                position = described_class.instance(:before, :third)
                added = position.apply_onto(actions, second)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end

            context 'when reference is the last action' do
              it 'places action before last' do
                actions = get_actions(:first, :second, :fourth)
                third = Action.instance(:third, :simple)
                position = described_class.instance(:before, :fourth)
                added = position.apply_onto(actions, third)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end
          end

          context 'with position as :after' do
            context 'when reference is the first action' do
              it 'places action at second place' do
                actions = get_actions(:first, :third, :fourth)
                second = Action.instance(:second, :simple)
                position = described_class.instance(:after, :first)
                added = position.apply_onto(actions, second)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end

            context 'when reference is in the middle' do
              it 'places action after the reference' do
                actions = get_actions(:first, :second, :fourth)
                third = Action.instance(:third, :simple)
                position = described_class.instance(:after, :second)
                added = position.apply_onto(actions, third)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end

            context 'when reference is the last action' do
              it 'places action at the last place' do
                actions = get_actions(:first, :second, :third)
                fourth = Action.instance(:fourth, :simple)
                position = described_class.instance(:after, :third)
                added = position.apply_onto(actions, fourth)
                expect(added.map(&:name)).to eq(%i[first second third fourth])
              end
            end
          end

          it 'raises if reference not found' do
            actions = get_actions(:first, :second, :third)
            fourth = Action.instance(:fifth, :simple)
            position = described_class.instance(:after, :fourth)
            expect do
              position.apply_onto(actions, fourth)
            end.to raise_error(Error)
          end

          it 'raises if reference ambiguous' do
            actions = get_actions(:fourth, :second, :fourth)
            fourth = Action.instance(:third, :simple)
            position = described_class.instance(:before, :fourth)
            expect do
              position.apply_onto(actions, fourth)
            end.to raise_error(Error)
          end

          context 'with position as :at' do
            it 'replaces action if exists' do
              actions = get_actions(:first, :second, :third)
              second_new = Action.instance(:second_new, :simple)
              position = described_class.instance(:at, :second)
              added = position.apply_onto(actions, second_new)
              expect(added.map(&:name)).to eq(%i[first second_new third])
            end

            it 'raises if action to replace not found' do
              actions = get_actions(:first, :second, :third)
              fourth_new = Action.instance(:fourth_new, :simple)
              position = described_class.instance(:at, :fourth)
              expect do
                position.apply_onto(actions, fourth_new)
              end.to raise_error(Error)
            end
          end
        end
      end
    end
  end
end
