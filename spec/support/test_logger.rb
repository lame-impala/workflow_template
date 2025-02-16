# frozen_string_literal: true

module WorkflowTemplate
  class Logger
    attr_reader :name

    def initialize(name: nil)
      @name = name&.to_sym
      @messages = []
      freeze
    end

    def debug(msg)
      log(msg)
    end

    def log(msg)
      @messages << msg
      nil
    end

    def messages
      @messages || []
    end

    def self.instance
      @instance ||= reset
    end

    def self.log(msg)
      instance.log(msg)
    end

    def self.reset
      @instance = Logger.new(name: :global)
    end

    def self.messages
      instance.messages
    end
  end
end
