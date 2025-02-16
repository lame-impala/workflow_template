# frozen_string_literal: true

module WorkflowTemplate
  class Error < RuntimeError; end

  class Fatal < Error
    class ArgumentError < Fatal
      def initialize(action_name, message)
        full_message = "Argument mismatch in '#{action_name}': #{message}"

        super(full_message)
      end

      def self.depth(argument_error, method)
        path, = method.source_location
        label = method.name.to_s
        _, index = argument_error.backtrace_locations.each_with_index.find do |location, _index|
          location.label == label && location.path == path
        end

        index
      end
    end

    class InconsistentState < Fatal
    end

    class BadActionReturn < Fatal
      def initialize(action_name, value)
        full_message = <<~ERR.squish
          Invalid return from '#{action_name}' action, nil or Hash expected,
          got '#{value.inspect}' (#{value.class.name})
        ERR

        super(full_message)
      end
    end

    class BadReturnKeys < Fatal
      def initialize(action_name, keys)
        keys = keys.map { |key| "'#{key.inspect}' (#{key.class.name})" }
        full_message = "Invalid return from '#{action_name}' action, symbolic keys expected, got #{keys.join(', ')}"
        super(full_message)
      end
    end

    class BadValidationReturn < Fatal
      def initialize(action_name)
        full_message = "Invalid return from '#{action_name}' validation"
        super(full_message)
      end
    end

    class BadInput < Fatal
      def initialize(value)
        full_message = "Invalid input, Hash expected, got '#{value.inspect}' (#{value.class.name})"
        super(full_message)
      end
    end

    class Detailed < Fatal
      def initialize(action_name, input, message)
        full_message = "Fatal error in '#{action_name}': #{message}, input: #{input.inspect}"
        super(full_message)
      end
    end

    class ForeignCodeError < Fatal
      attr_reader :foreign_error

      def initialize(foreign_error)
        @foreign_error = foreign_error
        full_message = "Foreign error #{foreign_error.class.name}: #{foreign_error.message}"
        super(full_message)
      end
    end

    class UnexpectedNil < Fatal
      def initialize(action_name)
        full_message = "Nil return from '#{action_name}', nil is not allowed for 'update' state transition strategy"
        super(full_message)
      end
    end

    class Unimplemented < Fatal
      def initialize(action_name)
        super("Unimplemented method: '#{action_name}'")
      end
    end
  end

  class ExecutionError < Error
    def initialize(original_error)
      @original_error = original_error
      super(original_error.to_s)
      freeze
    end
  end
end
