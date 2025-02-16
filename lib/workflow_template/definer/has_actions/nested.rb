# frozen_string_literal: true

require_relative 'redefine'
require_relative 'description'
require_relative 'dsl'

module WorkflowTemplate
  module Definer
    module HasActions
      module Nested
        include HasActions

        def describe
          raise Error, "Can't describe unfrozen workflow" unless frozen?

          Description.new(self)
        end

        module Unprepared
          include Dsl
          include Nested
          include HasActions::Redefine

          def prepare(*args)
            unprepared = self

            target = Module.new do
              extend Prepared

              define_singleton_method :unprepared do
                unprepared
              end
            end

            actions.wrapper.each do |action|
              target.send :store_wrapper_action, action.prepare(*args)
            end
            actions.simple.each do |action|
              position = Position.instance(:after, nil)
              target.send :store_action, action.prepare(*args), position
            end
            target.freeze
          end

          def redefine(&block)
            redefine_onto(Unprepared, &block)
          end
        end

        module Prepared
          include Nested
          include Performer

          def prepare(*args)
            unprepared.prepare(*args)
          end

          def redefine(&block)
            unprepared.redefine(&block)
          end
        end
      end
    end
  end
end
