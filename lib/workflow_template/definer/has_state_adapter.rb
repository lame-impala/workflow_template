# frozen_string_literal: true

require_relative '../adapters/state/default'
require_relative '../workflow/description'

module WorkflowTemplate
  module Definer
    module HasStateAdapter
      def state_adapter(*args)
        case args.length
        when 0
          return @state_adapter if defined? @state_adapter
          if defined?(superclass) && superclass.respond_to?(:state_adapter)
            return superclass.state_adapter
          end

          State::Adapter.fetch(:default)
        when 1 then @state_adapter = State::Adapter.fetch(args[0])
        else raise Error, "Unexpected arguments for state adapter: '#{args}'"
        end
      end

      def freeze
        @state_adapter = state_adapter unless frozen?

        super
      end
    end
  end
end
