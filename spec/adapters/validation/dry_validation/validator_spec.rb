# frozen_string_literal: true

require 'spec_helper'
require 'dry-validation'
require 'support/test_validation_collection'

require_relative '../../../../lib/workflow_template/adapters/validation/dry_validation'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  module Adapters
    module Validation
      module DryValidation
        class Profile
          attr_reader :age

          def initialize(age)
            @age = age
          end
        end

        class TestContract < Dry::Validation::Contract
          option(:profile)

          params do
            required(:email).filled(:string)
            required(:age).value(:integer)
          end

          rule(:email) do
            key.failure('has invalid format') unless /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i.match?(value)
          end

          rule(:age) do
            key.failure('must be greater than 18') if value <= profile.age
          end
        end

        RSpec.describe Validator do
          subject(:result) { validation.call({ params: params, profile: profile }) }

          let(:validation) do
            WorkflowTemplate::Validation::Builder::Proxy
              .instance(DryValidation, TestValidationCollection)
              .with_context(:profile)
              .validate(:params, contract: TestContract)
          end
          let(:profile) { Profile.new(18) }

          context 'when params are nil' do
            let(:params) { nil }

            it 'returns failure' do
              expect(result)
                .to be_a(WorkflowTemplate::Validation::Result::Failure)
                .and have_attributes(
                  key: :params,
                  name: :params,
                  code: :input_null,
                  message: nil
                )
            end
          end

          context 'when params are invalid' do
            let(:params) { { email: 'bogus', age: 11 } }

            it 'returns failure' do
              expect(result)
                .to be_a(WorkflowTemplate::Validation::Result::Failure)
                .and have_attributes(
                  key: :params,
                  name: :params,
                  code: :input_invalid,
                  message: 'email has invalid format, age must be greater than 18',
                  data: have_attributes(
                    errors: have_attributes(
                      to_h: { email: ['has invalid format'], age: ['must be greater than 18'] }
                    )
                  )
                )
            end
          end

          context 'when model is valid' do
            let(:params) { { email: 'abc@example.com', age: 19 } }

            it 'returns success' do
              expect(result).to be(WorkflowTemplate::Validation::Result::Success)
            end
          end
        end
      end
    end
  end
end
