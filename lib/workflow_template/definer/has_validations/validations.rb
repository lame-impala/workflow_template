# frozen_string_literal: true

require 'set'
require 'forwardable'
require_relative '../../error'
require_relative '../../validation/evaluation/abstract'

module WorkflowTemplate
  module Definer
    module HasValidations
      module Validations
        def self.merge_entries(current_entry, new_entry)
          new_entry = normalize_entry(new_entry)
          return new_entry if current_entry.nil?
          return current_entry if new_entry.nil?

          entry_to_set(current_entry) | entry_to_set(new_entry)
        end

        def self.entry_to_set(entry)
          case entry
          when Set then entry
          when Array then entry.to_set
          else Set.new([entry])
          end
        end

        def self.normalize_entry(entry)
          case entry
          when nil then nil
          when Array, Set then entry.to_a.to_set(&:to_sym)
          else entry.to_sym
          end
        end

        class Unprepared
          def self.instance
            new
          end

          attr_reader :declarations

          def initialize(declarations: {}, input_set: nil, output_set: nil)
            @declarations = declarations.freeze
            @input_set = Validations.normalize_entry(input_set)
            @output_set = Validations.normalize_entry(output_set)
          end

          private_class_method :new

          def add(declaration)
            raise Error, "Declaration name taken: '#{declaration.name}'" if @declarations.key? declaration.name
            raise Error, "Validation '#{declaration.name}' not properly declared" unless valid_declaration?(declaration)

            @declarations = declarations.merge(declaration.name => declaration).freeze
            declaration
          end

          def validate_input(entry)
            @input_set = Validations.merge_entries(@input_set, entry)
          end

          def validate_output(entry)
            @output_set = Validations.merge_entries(@output_set, entry)
          end

          def prepared
            Prepared.instance declarations: declarations, input: input_set, output: output_set
          end

          def freeze
            raise Error, "Freeze is unimplemented for #{self.class.name}, call #prepared instead"
          end

          protected

          attr_reader :input_set, :output_set

          def valid_declaration?(declaration)
            declaration.is_a?(Validation::Evaluation::Abstract)
          end
        end

        class Prepared
          attr_reader :declarations, :input, :output

          def self.instance(declarations:, input:, output:)
            new(declarations, normalize_entry(input), normalize_entry(output))
          end

          def self.normalize_entry(entry)
            case entry
            when nil then nil
            when Array, Set then entry.to_a.map(&:to_sym)
            else entry.to_sym
            end
          end

          private_class_method :new

          def initialize(declarations, input, output)
            @declarations = declarations.freeze
            @input = input.freeze
            @output = output.freeze
            freeze
          end

          def merge(other)
            merged_validations = declarations.merge other.declarations
            merged_input = Validations.merge_entries(input, other.send(:input_set))
            merged_output = Validations.merge_entries(output, other.send(:output_set))

            Prepared.instance(
              declarations: merged_validations,
              input: merged_input,
              output: merged_output
            )
          end

          def resolve_validations(option)
            case option
            when nil then nil
            when Array then option.map { |element| resolve_validation(element) }.freeze
            else resolve_validation(option).freeze
            end
          end

          def resolve_validation(name)
            name = name.to_sym
            raise Error, "Validation not declared: #{name}" unless declarations.key? name

            declarations[name]
          end

          def resolved
            Resolved.new(self)
          end
        end

        class Resolved
          extend Forwardable

          def_delegators :@prepared, :declarations
          def_delegators :@prepared, :input
          def_delegators :@prepared, :output

          def_delegators :@prepared, :merge
          def_delegators :@prepared, :resolve_validations

          def initialize(prepared)
            @prepared = prepared
            @input_validations = prepared.resolve_validations(prepared.input)
            @output_validations = prepared.resolve_validations(prepared.output)
            freeze
          end

          attr_reader :input_validations, :output_validations
        end
      end
    end
  end
end
