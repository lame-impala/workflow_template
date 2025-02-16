# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../lib/workflow_template/outcome/statuses'

module WorkflowTemplate
  class Outcome
    RSpec.describe Statuses do
      subject(:statuses) { described_class.new }

      describe '#handled!' do
        it 'marks status as handled' do
          updated = statuses.handled!(:ok)
          expect(updated.unhandled?(:ok)).to be(false)
        end
      end

      describe '#on_default_detected!' do
        context 'when detected is true' do
          it 'sets status as having default' do
            updated = statuses.on_default_detected(:error, true)
            expect(updated.unhandled?(:ok)).to be(true)
          end
        end

        context 'when detected is false' do
          it "doesn't alter the status" do
            updated = statuses.on_default_detected(:error, true)
            updated = updated.on_default_detected(:error, false)
            expect(updated.unhandled?(:ok)).to be(true)
          end
        end
      end

      context 'when no statuses are handled' do
        it 'reports missing default' do
          expect(statuses).to be_default_missing
          expect(statuses.default_missing).to contain_exactly(:ok, :error)
        end

        it 'reports all statuses as unhandled' do
          expect(statuses.unhandled?(:ok)).to be(true)
          expect(statuses.unhandled?(:error)).to be(true)
        end
      end

      context 'when status is handled but has not default' do
        let(:statuses) do
          described_class.new.handled!(:error)
        end

        it 'reports missing default' do
          expect(statuses.default_missing).to contain_exactly(:ok, :error)
        end

        it 'reports the handled status as handled' do
          expect(statuses.unhandled?(:ok)).to be(true)
        end

        it 'reports the other status as unhandled' do
          expect(statuses.unhandled?(:error)).to be(false)
        end
      end

      context 'when status has default but is not handled' do
        let(:statuses) do
          described_class.new.on_default_detected(:error, true)
        end

        it 'reports default present for the status' do
          expect(statuses.default_missing).to contain_exactly(:ok)
        end

        it 'reports all statuses as unhandled' do
          expect(statuses.unhandled?(:ok)).to be(true)
          expect(statuses.unhandled?(:error)).to be(true)
        end
      end
    end
  end
end
