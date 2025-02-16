# frozen_string_literal: true

require_relative '../../lib/workflow_template/workflow'
require_relative 'test_model'
require_relative 'test_logger'
require_relative 'test_validation_adapter'

module WorkflowTemplate
  class TestBase
    extend Workflow::ModuleMethods

    class BaseError < StandardError; end

    declare_validation(:array_present, using: :generic).validate(:array) { !_1.empty? }

    wrap_template(:log_base)
    wrap_template(:noop_base)

    apply(:second, validate: :array_present)
    and_then(:fifth, validate: :array_present)

    def noop_base(**opts, &block)
      block.call(**opts)
    end

    def log_base(input, &block)
      Logger.log('start base')
      raise 'Raised in Base logger before' if input[:raise_in_base_logger] == :before

      retval = block.call({ **input, last_in: :base })
      raise 'Raised in Base logger after' if input[:raise_in_base_logger] == :after

      Logger.log('end base')
      if retval[:error].is_a? BaseError
        { error: :base, last_out: :base }
      else
        { base: :ok, last_out: :base }
      end
    end

    def second(array:, **)
      { array: [*array, 2] }
    end

    def fifth(array:, **)
      { array: [*array, 5] }
    end

    freeze
  end

  class TestDesc < TestBase
    class DescError < StandardError; end

    default_validation_adapter :test
    declare_validation(:last_in_not_nil).validate(:last_in).to_not_eq(nil)
    declare_validation.validate(:extra).to_not_eq(nil)
    validate_input(:last_in_not_nil)

    wrap_template(:log_desc)
    wrap_template(:noop_desc)

    prepend_action.apply(:first)
    append_action(after: :second).apply(
      :third,
      defaults: { extra: 'Extra' },
      state: :merge,
      validate: :extra
    )
    prepend_action(before: :fifth).apply(:fourth)
    append_action.apply(:sixth)

    def noop_desc(**opts, &block)
      block.call(**opts)
    end

    def log_desc(**input, &block)
      Logger.log('start desc')
      retval = block.call({ **input, last_in: :desc })
      Logger.log('end desc')
      if retval[:error].is_a? DescError
        { error: :desc, last_out: :base }
      else
        { desc: :ok, last_out: :desc }
      end
    end

    def first(**)
      { array: [1] }
    end

    def third(array:, extra: nil, **opts)
      case opts[:outcome]
      when nil
        { array: [*array, 3], extra: extra }
      when :raise_base
        raise TestBase::BaseError, 'Raised in third'
      when :raise_desc
        raise TestDesc::DescError, 'Raised in third'
      when :return_error
        { error: :returned_from_third }
      else
        "Unimplemented: #{opts[:outcome]}"
      end
    end

    def fourth(array:, **)
      { array: [*array, 4] }
    end

    def sixth(array:, **)
      { array: [*array, 6] }
    end

    freeze
  end
end
