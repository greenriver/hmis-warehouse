###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    # object is an OpenStruct with:
    # {
    #   step: Hmis::WorkflowExecution::Step,
    #   referral: Hmis::Ce::Referral,
    # }
    # Why: The Step schema object should resolve this step's potential Participants (ReferralParticipants on the Referral).
    # However, the Step model does not have a direct relationship to Referral, to avoid a duplicative bidirectional relationship.

    field :id, ID, null: false, description: 'unique identifier for this step based on node and instance'
    field :step_id, ID, null: true, method: :id, description: 'the DB identifier of this step, if it is persisted'
    field :form_definition, Types::Forms::FormDefinition, null: false
    field :name, String, null: false
    field :status, HmisSchema::Enums::CeReferralStepStatus, null: false
    field :submitted_values, JsonObject, null: true
    field :swimlane, HmisSchema::CeReferralSwimlane, null: false, description: 'Swimlane for this step, which holds information about potential step participants'
    field :assignees, [Application::User], null: false, description: 'User(s) currently assigned to this step'

    def id
      # the step may not yet be persisted, such as when it isn't yet available in the workflow
      "#{object.step.node_id}:#{object.step.instance_id}"
    end

    def step_id
      object.step.id
    end

    def name
      workflow_task.name
    end

    def status
      object.step.status
    end

    def submitted_values
      object.step.submitted_values
    end

    def swimlane
      swimlane = load_ar_association(object.step, :swimlane)
      participants_by_swimlane_id = object.referral.participants.group_by(&:swimlane_id)

      raise "Workflow Step #{id} does not have a swimlane" unless swimlane.present?

      OpenStruct.new(
        id: swimlane.id,
        name: swimlane.name,
        participants: participants_by_swimlane_id[swimlane.id]&.map(&:user) || [],
      )
    end

    def assignees
      load_ar_association(object.step, :assignments)&.map(&:user)
    end

    def form_definition # Don't resolve in batch
      # If the step has been submitted before, it stores a reference to the definition it was submitted with
      definition = object.form_definition
      return definition if definition.present?

      # Otherwise, get the definition identifier on the node, and return the latest published definition with this identifier
      workflow_task.form_definitions.published.order(version: :desc).first
    end

    private

    # the Hmis::WorkflowDefinition::Task that configures this referral step
    def workflow_task
      # safe to call object.step because it's already loaded on the OpenStruct
      load_ar_association(object.step, :task)
    end
  end
end
