# frozen_string_literal: true

require 'active_model'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        class NullModel
          include ::ActiveModel::Validations
          include ::ActiveModel::Naming

          @_model_name = ::ActiveModel::Name.new(self, nil, 'Unknown')

          def base
            nil
          end

          validates :base, presence: true
        end
      end
    end
  end
end
