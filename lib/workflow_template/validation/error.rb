# frozen_string_literal: true

require_relative '../error'

module WorkflowTemplate
  module Validation
    class Error < WorkflowTemplate::Error
      attr_reader :failure

      def initialize(failure)
        @failure = failure
        super(failure.describe)
      end
    end
  end
end
