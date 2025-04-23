###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    # object is a Hmis::WorkflowExecution::Step

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
      # todo @martha
      # step DOES have relation to swimlane, through task, so that part is fine
      # swimlanes = load_ar_association(object, :swimlane)&.name

      # but we want to "zip this up" with participants, similar to what I just added in the referral schema object,
      # but we don't have access to participants here.
      # maybe through the instance -> referral? but that relationship doesn't currently exist
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
