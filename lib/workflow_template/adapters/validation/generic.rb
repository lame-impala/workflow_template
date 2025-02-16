# frozen_string_literal: true

require_relative '../../validation/adapter'
require_relative 'generic/builder'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        extend WorkflowTemplate::Validation::Adapter

        def self.builder_class
          Builder
        end

        def self.result_type
          :boolean
        end

        register(:generic)
      end
    end
  end
end
