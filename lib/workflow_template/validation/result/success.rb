# frozen_string_literal: true

module WorkflowTemplate
  module Validation
    module Result
      module Success
        def self.success?
          true
        end

        def self.===(other)
          other.equal?(self)
        end

        freeze
      end
    end
  end
end
