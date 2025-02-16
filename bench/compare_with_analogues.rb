# frozen_string_literal: true

require 'benchmark'
require 'ruby-prof'
require 'dry/transaction'
require 'trailblazer/operation'

require_relative '../lib/workflow_template/workflow'

module WorkflowTemplate
  class BenchWorkflow < Workflow
    default_state_transition_strategy :update

    apply(:first)
    and_then(:second)
    and_then(:third)

    def first(input:)
      { intermediate: input + 1 }
    end

    def second(intermediate:)
      { intermediate: intermediate + 1 }
    end

    def third(intermediate:)
      { final: intermediate + 1 }
    end

    freeze
  end

  class BenchTransaction
    include Dry::Transaction

    step(:first)
    step(:second)
    step(:third)

    def first(input)
      Success(input + 1)
    end

    def second(intermediate)
      Success(intermediate + 1)
    end

    def third(intermediate)
      Success(intermediate + 1)
    end
  end

  class BenchOperation < Trailblazer::Operation
    step(:first)
    step(:second)
    step(:third)

    def first(ctx, input:, **)
      ctx[:intermediate] = input + 1
    end

    def second(ctx, intermediate:, **)
      ctx[:intermediate] = intermediate + 1
    end

    def third(ctx, intermediate:, **)
      ctx[:final] = intermediate + 1
    end
  end

  class Profile
    def self.run(n)
      result = RubyProf::Profile.profile do
        workflow = BenchWorkflow.impl

        n.times do
          workflow.perform({ input: 1 })
        end
      end

      printer = RubyProf::GraphPrinter.new(result)
      printer.print($stdout, {})
    end
  end

  module Benchmark
    def self.run(n) # rubocop:disable Metrics/AbcSize
      runs = {}

      workflow = BenchWorkflow.impl
      runs[:Workflow] = proc { workflow.perform({ input: 1 }, trace: false) }

      transaction = BenchTransaction.new
      runs[:Transaction] = proc { transaction.call(1) }

      operation = BenchOperation
      runs[:Operation] = proc { operation.call(input: 1) }

      runs.to_a.shuffle.each do |key, proc|
        result = ::Benchmark.measure { n.times { proc.call } }
        puts "#{key}: #{result}"
      end
    end
  end
end

# WorkflowTemplate::Profile.run(10_000)
WorkflowTemplate::Benchmark.run(10_000)
