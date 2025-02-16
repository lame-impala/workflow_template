# frozen_string_literal: true

require 'spec_helper'
require 'support/test_validation_collection'
require_relative '../../../../lib/workflow_template/definer/has_validations/validations'
require_relative '../../../../lib/workflow_template/adapters/validation/active_model/builder'
require_relative '../../../../lib/workflow_template/validation/builder/proxy'

module WorkflowTemplate
  module Definer
    module HasValidations
      RSpec.describe Validations do
        let(:proxy) do
          Validation::Builder::Proxy
            .instance(Adapters::Validation::ActiveModel, TestValidationCollection)
        end

        let(:foo) { proxy.validate(:foo) }
        let(:bar) { proxy.validate(:bar) }

        let(:unprepared) do
          Validations::Unprepared.instance.tap do |validations|
            validations.validate_input :foo
            validations.validate_output :bar
            validations.add(foo)
          end
        end

        describe Validations::Unprepared do
          describe '#prepared' do
            it 'passes input validations onto prepared collection' do
              expect(unprepared.prepared.input).to eq(:foo)
            end

            it 'passes output validations onto prepared collection' do
              expect(unprepared.prepared.output).to eq(:bar)
            end
          end
        end

        describe Validations::Prepared do
          let(:unprepared) do
            Validations::Unprepared.instance.tap do |validations|
              validations.validate_input [:foo]
              validations.validate_output [:bar]
              validations.add(foo)
            end
          end
          let(:prepared) { described_class.instance(input: [:bar], output: [:foo], declarations: { bar: bar }) }

          describe '#merge' do
            it 'merges new and existing input validations in correct order' do
              expect(prepared.merge(unprepared).input).to contain_exactly(:bar, :foo)
            end

            it 'merges new and existing output to in correct order' do
              expect(prepared.merge(unprepared).output).to contain_exactly(:foo, :bar)
            end

            it 'merges validation declarations' do
              expect(prepared.merge(unprepared).declarations).to eq({ foo: foo, bar: bar })
            end
          end
        end
      end
    end
  end
end
