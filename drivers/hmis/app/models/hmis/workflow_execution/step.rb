# frozen_string_literal: true

# Represents an individual task instance within a workflow execution.
# Tracks the state, assignments, and completion data for a specific
# task node.
module Hmis::WorkflowExecution
  class Step < GrdaWarehouseBase
    include SimpleStateMachine

    belongs_to :instance, class_name: 'Hmis::WorkflowExecution::Instance'
    belongs_to :node, class_name: 'Hmis::WorkflowDefinition::Node'
    belongs_to :task, class_name: 'Hmis::WorkflowDefinition::Task', foreign_key: 'node_id'
    belongs_to :form_definition, class_name: 'Hmis::Form::Definition', optional: true # The form definition that was (last) used to submit the step, if it has been submitted
    has_one :swimlane, through: :task, class_name: 'Hmis::WorkflowDefinition::Swimlane'

    has_many :assignments, class_name: 'Hmis::WorkflowExecution::StepAssignment', dependent: :destroy

    # TODO(#7395): permissions
    scope :viewable_by, ->(_user) { all }

    scope :open, -> do
      # Used for returning the "current" step of a referral.
      step_t = Hmis::WorkflowExecution::Step.arel_table

      where(status: ['available', 'in_progress']).
        # Prioritize in_progress steps over available ones
        order(Arel::Nodes::Case.new.when(step_t[:status].eq('in_progress')).then(1).else(2)).
        order(step_t[:id]) # Fallback to order by ID so it's determinate
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
