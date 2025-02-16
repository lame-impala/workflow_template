# frozen_string_literal: true

require_relative 'workflow_template/workflow'

module WorkflowTemplate
  VERSION = '0.0.3'

  def self.gem_version
    ::Gem::Version.new(VERSION)
  end
end
