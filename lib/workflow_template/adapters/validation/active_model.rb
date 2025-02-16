# frozen_string_literal: true

require_relative '../../validation/adapter'
require_relative 'active_model/builder'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        extend WorkflowTemplate::Validation::Adapter

        def self.builder_class
          Builder
        end

        def self.result_type
          :canonical
        end

        register(:active_model)
      end
    end
  end
end
