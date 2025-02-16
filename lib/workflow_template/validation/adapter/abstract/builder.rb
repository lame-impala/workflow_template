# frozen_string_literal: true

require_relative '../../builder/error'
require_relative '../../evaluation'

module WorkflowTemplate
  module Validation
    module Adapter
      module Abstract
        class Builder
          Error = Validation::Builder::Error

          def initialize(proxy)
            @proxy = proxy
          end

          def validate
            self
          end

          private

          attr_reader :proxy
        end
      end
    end
  end
end
