# frozen_string_literal: true

require_relative '../../lib/workflow_template/adapters/validation/active_model'

module WorkflowTemplate
  class TestModel
    include ::ActiveModel::Validations
    include ::ActiveModel::Naming

    validates :value, numericality: { greater_than: 0 }

    def initialize(value)
      @value = value
      @saved = false
    end

    attr_reader :value

    def value=(value)
      @saved = false
      @value = value
    end

    def save!
      @saved = true if valid?
    end

    def saved?
      @saved
    end
  end
end
