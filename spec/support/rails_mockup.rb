# frozen_string_literal: true

module WorkflowTemplate
  class Rails
    class Env
      def initialize(name)
        @name = name.to_sym
        freeze
      end

      def production?
        @name == :production
      end
    end

    def self.env(*args)
      case args.length
      when 0 then @env ||= Env.new(:test)
      when 1 then @env = Env.new(args[0])
      else raise "Unexpected arguments: #{args}"
      end
    end
  end

  class ActiveRecord
    class RecordNotFound < StandardError; end

    module Base
      class Connection
        def self.open_transactions
          @open_transactions ||= 0
        end

        def self.transaction_id
          @transaction_id ||= 0
        end

        def self.transaction(&block)
          self.transaction_id += 1
          self.open_transactions += 1
          block.call
        ensure
          self.open_transactions -= 1
        end

        class << self
          attr_writer :open_transactions
        end

        class << self
          attr_writer :transaction_id
        end

        private_class_method :open_transactions=
        private_class_method :transaction_id=
      end

      def self.connection
        @connection ||= Connection
      end
    end
  end
end
