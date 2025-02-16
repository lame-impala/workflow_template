# frozen_string_literal: true

require_relative 'action/simple'
require_relative 'action/wrapper'
require_relative 'action/nested'

module WorkflowTemplate
  module Action
    def self.instance(name, type, **opts)
      case type
      when :simple
        Simple::Unprepared.new(name, **opts)
      when :wrapper
        Wrapper::Unprepared.new(name, **opts)
      else
        raise Error, "Unimplemented action type: #{type}"
      end
    end
  end
end
