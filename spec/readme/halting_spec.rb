# frozen_string_literal: true

require_relative '../../lib/workflow_template'
require_relative '../support/readme_helper'
require_relative '../support/test_model'

module WorkflowTemplate
  module Readme
    RSpec.describe 'README: halting' do
      # rubocop:disable Security/Eval, RSpec/NoExpectationExample
      context 'when `halted` key is set' do
        it 'halts' do
          eval(ReadmeHelper.specs[:halting_workflow])
        end
      end
      # rubocop:enable Security/Eval, RSpec/NoExpectationExample
    end
  end
end
