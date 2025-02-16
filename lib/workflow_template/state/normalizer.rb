# frozen_string_literal: true

module WorkflowTemplate
  module State
    class Normalizer
      attr_reader :keys

      def initialize(keys)
        @keys = keys&.map(&:to_sym).freeze
        freeze
      end

      def normalize(hash)
        return hash if keys.nil?

        keys.each_with_object({}) do |key, normalized|
          normalized[key] = hash[key]
        end.freeze
      end

      private_class_method :new

      def self.instance(keys = nil)
        return null_object if keys.nil?

        new keys
      end

      def self.null_object
        @null_object ||= new(nil)
      end
    end
  end
end
