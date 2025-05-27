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
    field :swimlane, String, null: false
    field :submitted_values, JsonObject, null: true
    delegate :name, to: :workflow_task
    field :assignees, [Application::User], null: false, description: 'User(s) currently assigned to this step'
    field :updated_by, Application::User, null: true
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: true

    def id
      # the step may not yet be persisted, such as when it isn't yet available in the workflow
      "#{object.node_id}:#{object.instance_id}"
    end

    def swimlane
      load_ar_association(object, :swimlane)&.name
    end

    def assignees
      if object.persisted?
        load_ar_association(object, :assignments)&.map(&:user)
      else
        object.assignments.map(&:user)
      end
    end

    def form_definition # Don't resolve in batch
      # If the step has been submitted before, it stores a reference to the definition it was submitted with
      definition = object.form_definition
      return definition if definition.present?

      # Otherwise, get the definition identifier on the node, and return the latest published definition with this identifier
      workflow_task.form_definitions.published.order(version: :desc).first
    end

    def updated_by
      load_last_user_from_versions(object)
    end

    private

    # the Hmis::WorkflowDefinition::Task that configures this referral step
    def workflow_task
      load_ar_association(object, :task)
    end
  end
end
