###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    # object is a Hmis::WorkflowExecution::Step, AND also expects context[:referral] is a Hmis::Ce::Referral.
    # Why: The Step schema object should resolve this step's potential Participants (ReferralParticipants on the Referral).
    # However, the Step model does not have a direct relationship to Referral, since it lives under Workflow Execution and not CE.
    # But we do always have the referral on hand when resolving the step, so we can stick it into the context and then use it on the schema object.
    # Alternatives considered:
    # - Add relationship from Step to Referral, probably through Instance.
    #   Decided against this in order to avoid a duplicative bidirectional relationship.
    # - Always resolve the Referral alongside the Step, and expect the frontend to use the Participants from the Referral.
    #   Decided against this because we want the frontend schema shape to match what would be most useful for the UI to display the data,
    #   so we do want to put the participant on the Step.

    field :id, ID, null: false, description: 'unique identifier for this step based on node and instance'
    field :step_id, ID, null: true, method: :id, description: 'the DB identifier of this step, if it is persisted'
    field :form_definition, Types::Forms::FormDefinition, null: false
    field :name, String, null: false
    field :status, HmisSchema::Enums::CeReferralStepStatus, null: false
    field :submitted_values, JsonObject, null: true
    field :swimlane, HmisSchema::CeReferralSwimlane, null: false, description: 'Swimlane for this step, which holds information about potential step participants'
    field :assignees, [Application::User], null: true, description: 'Assignee(s) currently working on this step'
    delegate :name, to: :workflow_node

    def id
      # the step may not yet be persisted, such as when it isn't yet available in the workflow
      "#{object.node_id}:#{object.instance_id}"
    end

    def workflow_node
      load_ar_association(object, :node)
    end

    def swimlane
      swimlane = load_ar_association(object, :swimlane)
      referral = context[:referral] # get the referral from context, because WFE Step doesn't have a direct relationship to CE Referral
      participants_by_swimlane_id = referral.participants.group_by(&:swimlane_id)

      {
        id: swimlane.id,
        name: swimlane.name,
        participants: participants_by_swimlane_id[swimlane.id]&.map(&:user) || [],
      }
    end

    def assignees
      load_ar_association(object, :assignments)&.map(&:user)
    end

    def form_definition
      # If the step has been submitted before, it stores a reference to the definition it was submitted with
      definition = load_ar_association(object, :form_definition)
      return definition if definition.present?

      # Otherwise, get the definition identifier on the node, and return the latest published definition with this identifier
      node = load_ar_association(object, :node)
      load_ar_association(node, :form_definitions, scope: Hmis::Form::Definition.published.order(version: :desc)).first
    end
  end
end
