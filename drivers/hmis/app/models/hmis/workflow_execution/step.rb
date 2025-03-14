# frozen_string_literal: true

# Represents an individual task instance within a workflow execution.
# Tracks the state, assignments, and completion data for a specific
# task node.
module Hmis::WorkflowExecution
  class Step < GrdaWarehouseBase
    include AASM

    belongs_to :instance, class_name: 'Hmis::WorkflowExecution::Instance'
    belongs_to :node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :task, class_name: 'Hmis::WorkflowDefinition::Task', foreign_key: 'node_id'
    has_one :swimlane, through: :task, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    has_many :assignments, class_name: 'Hmis::WorkflowExecution::StepAssignment', dependent: :destroy

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    # note, step status is not intended to be manipulated outside of the workflow engine
    aasm column: 'status' do
      state :unavailable, initial: true
      state :available
      state :in_progress
      state :completed

      # node can be started by a user
      event :enable do
        transitions from: [:unavailable, :completed], to: :available
      end

      # node can be disabled due to previous step being un-completed
      event :disable do
        transitions from: :available, to: :unavailable
      end

      # task is started
      event :start do
        transitions from: :available, to: :in_progress
      end

      # task is canceled by user
      event :cancel do
        transitions from: :in_progress, to: :available
      end

      # task is completed by a user
      event :complete do
        transitions from: :in_progress, to: :completed
      end

      event :undo_complete_step do
        transitions from: :completed, to: :in_progress
      end
    end
  end
end
