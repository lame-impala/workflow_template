# frozen_string_literal: true

require_relative '../../lib/workflow_template/adapters/validation/active_model'

module WorkflowTemplate
  class TestUser
    def initialize(access_rights)
      @access_rights = access_rights.to_set.freeze
    end

    attr_reader :access_rights

    def can?(action)
      access_rights.include? action
    end
  end
end
