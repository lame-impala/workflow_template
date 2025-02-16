# frozen_string_literal: true

module WorkflowTemplate
  module Validation
    module Result
      class Failure
        module Abstract
          def success?
            false
          end
        end
      end
    end
  end
end
