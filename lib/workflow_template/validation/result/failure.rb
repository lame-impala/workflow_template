# frozen_string_literal: true

require_relative 'failure/abstract'
require 'forwardable'

module WorkflowTemplate
  module Validation
    module Result
      class Failure
        include Abstract
        extend Forwardable

        attr_reader :name, :key, :failure

        def_delegator :failure, :data

        def self.instance(name, key, failure)
          new name, key, failure
        end

        def initialize(name, key, failure)
          @name = name.to_sym
          @key = key&.to_sym
          @failure = failure
          freeze
        end

        def code
          failure.code || :"#{name}_failed"
        end

        def describe
          "#{code}: #{name} #{failure.describe}"
        end

        def message(*args, **opts)
          failure.message(*args, **opts)
        end

        def eql?(other)
          return false unless other.is_a?(self.class)

          name == other.name
        end

        def hash
          name.hash
        end
      end
    end
  end
end
