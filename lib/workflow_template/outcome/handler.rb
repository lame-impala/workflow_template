# frozen_string_literal: true

require 'forwardable'
require_relative 'statuses'
require_relative '../validation/error'

module WorkflowTemplate
  class Outcome
    class Handler
      extend Forwardable

      attr_reader :final_state, :retval

      def_delegator :@statuses, :unhandled?
      def_delegator :@statuses, :default_missing?
      def_delegator :@statuses, :default_missing

      def initialize(final_state, statuses: Outcome::Statuses.new, retval: nil)
        @final_state = final_state
        @statuses = statuses
        @retval = retval
        freeze
      end

      def handle_status(status, binding: nil, **opts, &block) # rubocop:disable Metrics/AbcSize
        status = status.to_sym
        raise WorkflowTemplate::Error, "Handler for '#{status}' unexpected" if @statuses[status].default?

        statuses = @statuses.on_default_detected(status, self.class.default?(status, **opts))
        if unhandled?(final_state.status) && self.class.run_handler?(status, final_state, **opts)
          self.class.run_handler(status, statuses, final_state, binding: binding, &block)
        else
          Handler.new(final_state, statuses: statuses, retval: retval)
        end
      end

      def otherwise(binding: nil, &block)
        statuses = @statuses.all_defaults!
        if unhandled?(final_state.status)
          self.class.run_handler(final_state.status, statuses, final_state, binding: binding, &block)
        else
          Handler.new(final_state, statuses: statuses, retval: retval)
        end
      end

      def otherwise_unwrap(slice: nil, fetch: nil)
        statuses = @statuses.all_defaults!
        if unhandled?(final_state.status)
          Handler.new(
            final_state,
            statuses: statuses.handled!(final_state.status),
            retval: final_state.unwrap(slice: slice, fetch: fetch)
          )
        else
          Handler.new(final_state, statuses: statuses, retval: retval)
        end
      end

      def self.run_handler(status, statuses, final_state, binding: nil, &block)
        statuses = statuses.handled!(status)
        retval = final_state.state_class.run_handler!(final_state, binding, &block)
        Handler.new(final_state, statuses: statuses, retval: retval)
      end

      def self.default?(status, **opts)
        handler_strategy(status).default?(**opts)
      end

      def self.run_handler?(status, final_state, **opts)
        return false unless status == final_state.status

        handler_strategy(status).run_handler?(final_state, **opts)
      end

      def self.handler_strategy(status)
        case status
        when :ok then Ok
        when :error then Error
        else raise WorkflowTemplate::Error, "Unexpected status '#{status}'"
        end
      end

      module Ok
        def self.default?
          true
        end

        def self.run_handler?(_final_state)
          true
        end
      end

      module Error
        def self.default?(matcher: nil)
          matcher.nil?
        end

        def self.run_handler?(final_state, matcher: nil)
          # rubocop:disable Style/CaseEquality
          matcher.nil? || matcher === final_state.error
          # rubocop:enable Style/CaseEquality
        end
      end
    end
  end
end
