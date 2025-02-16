# frozen_string_literal: true

require_relative '../error'

module WorkflowTemplate
  class Workflow
    class Description
      def self.register(group, key, &block)
        registry[group][key] = block
      end

      def self.describe(workflow)
        description = new
        registry.each do |group, blocks|
          blocks.each_value do |block|
            result = block.call(workflow)
            next if result.nil?

            description.add!(result, group)
          end
        end
        description.format
      end

      def self.registry
        @registry ||= { initialize: {}, perform: {}, finalize: {} }
      end

      def initialize
        @initialize = []
        @perform = []
        @finalize = []
      end

      def add!(description, group)
        case group
        when :initialize then @initialize << description
        when :perform then @perform << description
        when :finalize then @finalize << description
        else raise Error, "Unexpected group: #{group}"
        end
      end

      def format
        [@initialize, @perform, @finalize].filter_map do |group|
          next if group.empty?

          formatted = group.map do |element|
            element.is_a?(String) ? element : element.format(level: 0)
          end
          formatted.join("\n")
        end.join("\n\n") << "\n"
      end
    end
  end
end
