###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    # object is a Hmis::WorkflowExecution::Step,
    # and also expects context[:referral] is a Hmis::Ce::Referral
    # todo @martha - add comments about why

    field :id, ID, null: false, description: 'unique identifier for this step based on node and instance'
    field :step_id, ID, null: true, method: :id, description: 'the DB identifier of this step, if it is persisted'
    field :form_definition, Types::Forms::FormDefinition, null: false
    field :name, String, null: false
    field :status, HmisSchema::Enums::CeReferralStepStatus, null: false
    field :submitted_values, JsonObject, null: true
    # todo @martha - add comments/clearer descirptions distinguishing btwn assignees and participants
    field :swimlane, HmisSchema::CeReferralSwimlane, null: false, description: 'Swimlane which holds information about step participants'
    field :assignees, [Application::User], null: true, description: 'Specific user(s) working on this step'
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
