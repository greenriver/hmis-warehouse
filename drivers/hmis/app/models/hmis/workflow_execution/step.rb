# frozen_string_literal: true

# Represents an individual task instance within a workflow execution.
# Tracks the state, assignments, and completion data for a specific
# task node.
module Hmis::WorkflowExecution
  class Step < GrdaWarehouseBase
    include SimpleStateMachine

    has_paper_trail

    belongs_to :instance, class_name: 'Hmis::WorkflowExecution::Instance'
    belongs_to :node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :user_task, class_name: 'Hmis::WorkflowDefinition::UserTask', foreign_key: 'node_id', optional: true
    belongs_to :script_task, class_name: 'Hmis::WorkflowDefinition::ScriptTask', foreign_key: 'node_id', optional: true
    belongs_to :form_definition, class_name: 'Hmis::Form::Definition', optional: true # The form definition that was (last) used to submit the step, if it has been submitted
    belongs_to :updated_by, class_name: 'Hmis::User', optional: true # User who last updated the step
    # There is no `created_by` user; a step is created by the workflow engine.

    has_one :swimlane, through: :user_task, class_name: 'Hmis::WorkflowDefinition::Swimlane'
    has_many :assignments, class_name: 'Hmis::WorkflowExecution::StepAssignment', dependent: :destroy

    scope :open, -> { where(status: ['available', 'in_progress']) }
    scope :excluding_unavailable, -> { where.not(status: 'unavailable') }
    scope :assigned_to, ->(user_id) do
      sa_t = Hmis::WorkflowExecution::StepAssignment.arel_table
      joins(:assignments).where(sa_t[:user_id].eq(user_id))
    end

    def open?
      [:available, :in_progress].include?(status.to_sym)
    end

    # note, step status is not intended to be manipulated outside of the workflow engine
    state_machine_config column: 'status' do
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
