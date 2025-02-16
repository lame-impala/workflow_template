# frozen_string_literal: true

module WorkflowTemplate
  module Validation
    module Adapter
      module Abstract
        module Validator
          def initialize
            freeze
          end

          def validate(_data)
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end

          def describe
            raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
          end
        end
      end
    end
  end
end
