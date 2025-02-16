# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/workflow_template/definer/has_output_normalizer'

module WorkflowTemplate
  module Definer
    class NotNormalizing
      extend HasOutputNormalizer

      def self.output_normalizer # rubocop:disable Lint/UselessMethodDefinition
        super
      end

      freeze
    end

    class NormalizingSuper < NotNormalizing
      normalize_output :foo

      freeze
    end

    class NormalizingSub < NormalizingSuper
      freeze
    end

    class NormalizingSubSub < NormalizingSub
      normalize_output :bar

      freeze
    end

    RSpec.describe HasOutputNormalizer do
      context 'when no normalizer is not defined' do
        it 'uses null normalizer' do
          expect(NotNormalizing.output_normalizer).to eq(State::Normalizer.null_object)
        end
      end

      context 'when no normalizer is defined on class' do
        it 'uses defined normalizer' do
          expect(NormalizingSuper.output_normalizer.keys).to eq([:foo])
        end
      end

      context 'when no normalizer is defined on superclass' do
        it 'uses normalizer from superclass' do
          expect(NormalizingSub.output_normalizer.keys).to eq([:foo])
        end
      end

      context 'when no normalizer is overridden on subclass' do
        it 'uses defined normalizer' do
          expect(NormalizingSubSub.output_normalizer.keys).to eq([:bar])
        end
      end
    end
  end
end
