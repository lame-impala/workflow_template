# frozen_string_literal: true

module WorkflowTemplate
  module Validation
    module Adapter
      module Abstract
        module Result
          module Failure
            def code
              raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
            end

            def message(*)
              raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
            end

            def data
              raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
            end
          end
        end
      end
    end
  end
end
