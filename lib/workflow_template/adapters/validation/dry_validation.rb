# frozen_string_literal: true

require_relative '../../validation/adapter'
require_relative 'dry_validation/builder'

module WorkflowTemplate
  module Adapters
    module Validation
      module DryValidation
        extend WorkflowTemplate::Validation::Adapter

        def self.builder_class
          Builder
        end

        def self.result_type
          :canonical
        end

        register(:dry_validation)
      end
    end
  end
end
