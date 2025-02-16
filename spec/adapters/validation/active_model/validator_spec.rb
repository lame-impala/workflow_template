# frozen_string_literal: true

require 'spec_helper'

require_relative '../../../../lib/workflow_template/adapters/validation/active_model'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'

require 'support/test_validation_collection'

module WorkflowTemplate
  module Adapters
    module Validation
      module ActiveModel
        class TestModel
          include ::ActiveModel::Validations
          include ::ActiveModel::Naming

          def initialize(foo: nil, bar: nil)
            @foo = foo
            @bar = bar
          end

          attr_accessor :foo, :bar

          validates :foo, presence: true
          validates :bar, numericality: { greater_than_or_equal_to: 0, less_than: 10 }
        end

        RSpec.describe Validator do
          subject(:result) { validation.call({ model: model }) }

          let(:validation) do
            WorkflowTemplate::Validation::Builder::Proxy
              .instance(ActiveModel, TestValidationCollection)
              .validate(:model)
          end

          context 'when model is nil' do
            let(:model) { nil }

            it 'returns failure' do
              expect(result)
                .to be_a(WorkflowTemplate::Validation::Result::Failure)
                .and have_attributes(
                  key: :model,
                  name: :model,
                  code: :model_nil,
                  message: "can't be blank",
                  data: have_attributes(full_messages: ["can't be blank"])
                )
            end
          end

          context 'when model is invalid' do
            let(:model) { TestModel.new(bar: 11) }

            it 'returns failure' do
              expect(result)
                .to be_a(WorkflowTemplate::Validation::Result::Failure)
                .and have_attributes(
                  key: :model,
                  name: :model,
                  code: :workflow_template_adapters_validation_active_model_test_model_invalid,
                  message: "Foo can't be blank and Bar must be less than 10",
                  data: have_attributes(full_messages: ["Foo can't be blank", 'Bar must be less than 10'])
                )
            end
          end

          context 'when model is valid' do
            let(:model) { TestModel.new(foo: 'FOO', bar: 5) }

            it 'returns success' do
              expect(result).to be(WorkflowTemplate::Validation::Result::Success)
            end
          end
        end
      end
    end
  end
end
