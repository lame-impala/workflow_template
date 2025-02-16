# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'
require_relative '../../../../lib/workflow_template/adapters/validation/generic'

module WorkflowTemplate
  module Validation
    module Builder
      RSpec.describe Proxy do
        let(:proxy) do
          described_class.instance(
            Adapters::Validation::Generic, TestValidationCollection
          )
        end

        context 'when context is specified' do
          context 'when key is missing' do
            it 'raises' do
              expected_message = 'Context is not available if key is not specified'
              expect do
                proxy.named(:model).with_context(:profile).validate
              end.to raise_error(WorkflowTemplate::Validation::Builder::Error, expected_message)
            end
          end

          context 'when key is present' do
            it 'builds evaluation with context' do
              validation = proxy.with_context(:profile).validate(:model) { |model| model == :model }
              expect(validation.context).to eq([:profile])
            end
          end
        end
      end
    end
  end
end
