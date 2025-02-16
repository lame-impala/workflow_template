# frozen_string_literal: true

require 'spec_helper'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class ReplaceSuper < Workflow
    apply(:first)
    and_then(:second)
    and_then(:third)

    def first(result:)
      { result: [*result, 'original 1st'] }
    end

    def second(result:)
      { result: [*result, 'original 2nd'] }
    end

    def third(result:)
      { result: [*result, 'original 3rd'] }
    end

    freeze
  end

  class ReplaceSub < ReplaceSuper
    replace_action(:first).apply(:new_first, defaults: { order: 1 })
    replace_action(:second).apply(:new_second, defaults: { order: 2 })
    replace_action(:third).apply(:new_third, defaults: { order: 3 }, state: :update)

    def new_third(result:, order:)
      { result: [*result, "replaced #{order}rd"] }
    end

    def new_first(result:, order:)
      { result: [*result, "replaced #{order}st"] }
    end

    def new_second(result:, order:)
      { result: [*result, "replaced #{order}nd"] }
    end

    freeze
  end

  class ReplaceWrapperSuper < Workflow
    apply(:before)
    and_then(:wrapper1) do
      and_then(:nested1)
    end
    and_then(:after)

    def before(result:, **)
      { result: [*result, 'before'] }
    end

    def wrapper1(result:, &block)
      block.call(result: [*result, 'wrapper1'])
      { wrapper: 'wrapper1' }
    end

    def nested1(result:, **)
      { result: [*result, 'nested1'] }
    end

    def after(result:, **)
      { result: [*result, 'after'] }
    end

    freeze
  end

  class ReplaceWrapperSub1 < ReplaceWrapperSuper
    replace_action(:wrapper1).apply(:wrapper2) do
      and_then(:nested2)
    end

    def wrapper2(result:, &block)
      block.call(result: [*result, 'wrapper2'])
      { wrapper: 'wrapper2' }
    end

    def nested2(result:, **)
      { result: [*result, 'nested2'] }
    end

    freeze
  end

  class ReplaceWrapperSub2 < ReplaceWrapperSub1
    inside_action(:wrapper2) do
      prepend_action(before: :nested2).apply(:before_nested)
      append_action(after: :nested2).apply(:after_nested)
    end

    def before_nested(result:, **)
      { result: [*result, 'before_nested'] }
    end

    def after_nested(result:, **)
      { result: [*result, 'after_nested'] }
    end

    freeze
  end

  class RemoveSuper < Workflow
    apply(:first)
    and_then(:second)
    and_then(:third)

    freeze
  end

  class RemoveSub < RemoveSuper
    prepend_action(before: :second).apply(:new_second)
    remove_action(:second)

    freeze
  end

  RSpec.describe '::replace_action' do
    it 'replaces simple actions' do
      description = <<~DESC
        state: merge

        new_first defaults: { order: 1 }
        new_second defaults: { order: 2 }
        new_third defaults: { order: 3 }, state: update
      DESC
      outcome = ReplaceSub.impl.perform({ result: [] }, trace: true)
      expect(ReplaceSub.describe).to eq(description)
      expect(outcome.meta.trace).to eq(%i[new_first new_second new_third])
      expected = ['replaced 1st', 'replaced 2nd', 'replaced 3rd']
      expect(outcome.data[:result]).to eq(expected)
    end

    it 'replaces wrapper actions' do
      description = <<~DESC
        state: merge

        before
        wrapper2
          nested2
        after
      DESC
      expect(ReplaceWrapperSub1.describe).to eq(description)
      outcome = ReplaceWrapperSub1.impl.perform({ result: [] }, trace: true)
      expect(outcome.meta.trace).to eq(%i[before wrapper2 nested2 after])
      expected = %w[before wrapper2 nested2 after]
      expect(outcome.data[:result]).to eq(expected)
      expect(outcome.data[:wrapper]).to eq('wrapper2')
    end
  end

  RSpec.describe '::inside_action' do
    it 'changes nested action' do
      description = <<~DESC
        state: merge

        before
        wrapper2
          before_nested
          nested2
          after_nested
        after
      DESC

      expect(ReplaceWrapperSub2.describe).to eq(description)
      outcome = ReplaceWrapperSub2.impl.perform({ result: [] }, trace: true)
      expect(outcome.meta.trace).to eq(%i[before wrapper2 before_nested nested2 after_nested after])
      expected = %w[before wrapper2 before_nested nested2 after_nested after]
      expect(outcome.data[:result]).to eq(expected)
      expect(outcome.data[:wrapper]).to eq('wrapper2')
    end
  end

  RSpec.describe '::remove_action' do
    it 'removes action' do
      description = <<~DESC
        state: merge

        first
        new_second
        third
      DESC

      expect(RemoveSub.describe).to eq(description)
    end
  end
end
