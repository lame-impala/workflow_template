# frozen_string_literal: true

require_relative '../../workflow/description'

module WorkflowTemplate
  module Definer
    module HasValidations
      module Description
        Workflow::Description.register(:initialize, :input_validations) do |workflow|
          next if void?(workflow.send(:validations).input)

          "validates input: #{describe_entry(workflow.send(:validations).input)}"
        end

        Workflow::Description.register(:finalize, :output_validations) do |workflow|
          next if void?(workflow.send(:validations).output)

          "validates output: #{describe_entry(workflow.send(:validations).output)}"
        end

        def self.describe_entry(entry)
          case entry
          when Array then "{ #{entry.join(', ')} }"
          else entry
          end
        end

        def self.void?(entry)
          case entry
          when nil then true
          when Symbol then false
          else entry.empty?
          end
        end
      end
    end
  end
end
