# frozen_string_literal: true

require_relative 'status'
require_relative '../error'

module WorkflowTemplate
  class Outcome
    class Statuses
      def initialize(ok: Status.new, error: Status.new)
        @statuses = { ok: ok, error: error }.freeze
        freeze
      end

      def status(status)
        status = status.to_sym
        raise Error, "Unsupported status: '#{status}'" unless @statuses.key? status

        @statuses[status]
      end

      def unhandled?(status)
        !status(status).handled?
      end

      def default_missing?
        @statuses.none? { |_, status| status.default? }
      end

      def default_missing
        @statuses.reject { |_, status| status.default? }.keys
      end

      alias [] status

      def handled!(status)
        updated = status(status).handled!
        self.class.new(**@statuses, status => updated)
      end

      def on_default_detected(status, detected)
        return self unless detected

        default!(status)
      end

      def default!(status)
        updated = status(status).default!
        self.class.new(**@statuses, status => updated)
      end

      def all_defaults!
        self.class.new(**@statuses.transform_values(&:default!))
      end

      def inspect
        "#<#{self.class.name} #{@statuses.map { |name, status| "#{name}: #{status.inspect}" }}>"
      end
    end
  end
end
