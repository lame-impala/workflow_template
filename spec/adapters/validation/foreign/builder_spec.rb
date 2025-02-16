# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../../../lib/workflow_template/adapters/validation/generic'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        RSpec.describe Builder do
          let(:proxy) { WorkflowTemplate::Validation::Builder::Proxy.instance(Generic, TestValidationCollection) }

          it 'builds validator using object' do
            validator = Module.new do
              def self.call(model)
                model.valid?
              end
            end

            validation = proxy.validate(:model)
                              .using(validator)
                              .validator
            expect(validation).to be_a(Generic::Object)
          end

          it 'builds block validation' do
            validation = proxy
                         .validate(:model) { |model| model == :model }
                         .validator
            expect(validation).to be_a(Generic::Block)
          end
        end
      end
    end
  end
end
