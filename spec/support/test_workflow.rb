# frozen_string_literal: true

require_relative 'test_model'
require_relative '../../lib/workflow_template/workflow'

module WorkflowTemplate
  class TestWorkflow
    extend Workflow::ModuleMethods
    declare_validation(using: :active_model).validate(:model)
    validate_input :model
    validate_output :model

    apply(:add, validate: :model)
    and_then(:multiply, validate: :model)

    def add(input)
      model = input[:model]

      if model.value < 20
        value = model.value + 4
        updated = TestModel.new(value)
        { model: updated }
      elsif model.value < 40
        { model: TestModel.new(nil) }
      elsif model.value < 60
        { error: RuntimeError.new("Too high: #{model.value}") }
      else
        raise "Value too high: #{model.value}"
      end
    end

    def multiply(input)
      model = input[:model]
      case model.value % 4
      when 0
        value = model.value * 3
        updated = TestModel.new(value)
        { model: updated }
      when 1
        { model: TestModel.new(nil) }
      when 2
        { error: RuntimeError.new("Not fit: #{model.value}") }
      else
        raise "Value not fit: #{model.value}"
      end
    end

    freeze
  end
end
