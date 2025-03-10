###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    # object is a Hmis::WorkflowExecution::Step

    field :id, ID, null: false # unique identifier for this step based on node and instance
    field :step_id, ID, null: true # the DB identifier of this step, if it is persisted
    field :form_definition, Types::Forms::FormDefinition, null: false
    field :name, String, null: false
    field :status, HmisSchema::Enums::CeReferralStepStatus, null: false
    field :swimlane, String, null: false
    field :submitted_values, JsonObject, null: true
    delegate :name, :form_definition, to: :workflow_node

    def id
      # the step may not yet be persisted, such as when it isn't yet available in the workflow
      "#{object.node_id}:#{object.instance_id}"
    end

    def step_id
      object.id
    end

    def workflow_node
      object.node
    end

    def swimlane
      load_ar_association(object, :node).swimlane.name
    end
  end
end
