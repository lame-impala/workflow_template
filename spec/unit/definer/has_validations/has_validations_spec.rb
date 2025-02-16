# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../../lib/workflow_template/definer/has_validations'
require_relative '../../../support/test_validation_adapter'

module WorkflowTemplate
  module Definer
    RSpec.describe HasValidations do
      let(:definer) do
        Class.new do
          extend HasValidations

          def self.validations # rubocop:disable Lint/UselessMethodDefinition
            super
          end
        end
      end

      describe '#declare_validation' do
        it 'adds declaration to the collection' do
          expect do
            definer.declare_validation(:new_validation, using: :test).validate(:key).to_not_eq(nil)
          end.to change { definer.validations.declarations.length }.from(0).to(1)
        end
      end

      describe '#validate_input' do
        it 'stores given validation' do
          expect do
            definer.validate_input :new_validation
          end.to change { definer.validations.input }.from(nil).to(:new_validation)
        end
      end

      describe '#validate output' do
        context 'with single validation' do
          it 'stores single validation' do
            expect do
              definer.validate_output :new_validation
            end.to change { definer.validations.output }.from(nil).to(:new_validation)
          end
        end

        context 'with multiple validations' do
          it 'stores collection of output validations' do
            expect do
              definer.validate_output %i[a b]
            end.to change { definer.validations.output }.from(nil).to(contain_exactly(:a, :b))
          end
        end
      end
    end
  end
end
