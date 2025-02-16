# frozen_string_literal: true

require_relative '../error'

module WorkflowTemplate
  module Action
    module Abstract
      module Prepared
        include Abstract

        def perform(state, receiver)
          raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
        end
      end

      module Named
        include Abstract

        attr_reader :name

        def initialize(name)
          @name = name.to_sym
          freeze
        end
      end

      module Unprepared
        include Named
      end

      def describe
        raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
      end

      def prepare(*)
        raise NotImplementedError, "#{self.class.name}##{__method__} unimplemented"
      end
    end
  end
end
