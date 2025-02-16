# frozen_string_literal: true

require_relative '../state'
require_relative '../workflow/description'

module WorkflowTemplate
  module Definer
    module HasOutputNormalizer
      Workflow::Description.register(:finalize, :output_normalizer) do |workflow|
        next if workflow.send(:output_normalizer).keys.nil?

        "normalizes output: #{workflow.send(:output_normalizer).keys.join(', ')}"
      end

      def normalize_output(*keys)
        @output_normalizer = State::Normalizer.instance(keys)
      end

      def freeze
        @output_normalizer = output_normalizer unless frozen?

        super
      end

      protected

      def output_normalizer
        return @output_normalizer if defined? @output_normalizer
        return State::Normalizer.instance unless defined?(superclass) && superclass.respond_to?(:output_normalizer)

        superclass.output_normalizer
      end
    end
  end
end
