module Hmis::WorkflowExecution
  class Step < GrdaWarehouseBase
    include AASM

    belongs_to :instance, class_name: 'Hmis::WorkflowExecution::Instance'
    belongs_to :node, class_name: 'Hmis::WorkflowDefinition::Node'

    aasm column: 'status' do
      state :unavailable, initial: true
      state :available
      state :in_progress
      state :completed

      event :enable do
        transitions from: :unavailable, to: :available
      end

      event :start do
        transitions from: :available, to: :in_progress
      end

      event :cancel do
        transitions from: :in_progress, to: :available
      end

      event :complete do
        transitions from: :in_progress, to: :completed
      end
    end
  end
end
