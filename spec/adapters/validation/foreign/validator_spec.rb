# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../../../lib/workflow_template/adapters/validation/generic'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  module Adapters
    module Validation
      module Generic
        class TestValidator
          def self.call(value)
            case value
            when :valid then true
            when :valid_with_detail then [true, :detail]
            when :invalid then false
            when :invalid_with_detail then [false, :detail]
            else raise 'Error in foreign code!'
            end
          end

          def self.describe
            'test validator'
          end
        end

        RSpec.describe Validator do
          context 'with object validation' do
            let(:validation) do
              WorkflowTemplate::Validation::Builder::Proxy
                .instance(Generic, TestValidationCollection, name: :key_is_valid)
                .validate(:key)
                .using(TestValidator)
            end

            it 'provides description' do
              expect(validation.describe).to eq('test validator')
            end

            it 'calls #validate method on supplied validator object' do
              allow(TestValidator).to receive(:call).and_call_original
              expect(validation.call({ key: :valid })).to eq(WorkflowTemplate::Validation::Result::Success)
              expect(TestValidator).to have_received(:call)
            end
          end

          context 'with block validation' do
            let(:validation) do
              WorkflowTemplate::Validation::Builder::Proxy
                .instance(Generic, TestValidationCollection, name: :key_is_valid)
                .validate(:key) { |value| TestValidator.call(value) }
            end

            context 'when validation returns true' do
              context 'with no details' do
                it 'returns original data' do
                  expect(validation.call({ key: :valid })).to eq(WorkflowTemplate::Validation::Result::Success)
                end
              end

              context 'with details' do
                it 'raises fatal error' do
                  expected_message = "Invalid return from 'key_is_valid' validation"
                  expect do
                    validation.call({ key: :valid_with_detail })
                  end.to raise_error(Fatal::BadValidationReturn, expected_message)
                end
              end
            end

            context 'when validation returns false' do
              context 'with no details' do
                it 'returns correctly populated failures object' do
                  result = validation.call({ key: :invalid })

                  expect(result)
                    .to be_a(WorkflowTemplate::Validation::Result::Failure)
                    .and have_attributes(
                      key: :key,
                      name: :key_is_valid,
                      code: :validation_failed,
                      message: 'block validation',
                      data: nil
                    )
                end
              end

              context 'with details' do
                it 'returns correctly populated failures object' do
                  result = validation.call({ key: :invalid_with_detail })

                  expect(result)
                    .to be_a(WorkflowTemplate::Validation::Result::Failure)
                    .and have_attributes(
                      key: :key,
                      name: :key_is_valid,
                      data: :detail
                    )
                end
              end
            end

            context 'when validation raises' do
              it 'raises fatal error' do
                expected_message = 'Foreign error RuntimeError: Error in foreign code!'
                expect do
                  validation.call({ key: :bogus })
                end.to raise_error(Fatal::ForeignCodeError, expected_message)
              end
            end
          end
        end
      end
    end
  end
end
