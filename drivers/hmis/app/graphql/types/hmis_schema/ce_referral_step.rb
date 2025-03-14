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
    delegate :name, to: :workflow_node

    def id
      # the step may not yet be persisted, such as when it isn't yet available in the workflow
      "#{object.node_id}:#{object.instance_id}"
    end

    def workflow_node
      object.node
    end

    def swimlane
      load_ar_association(object, :swimlane)&.name
    end

    def form_definition
      load_ar_association(object.node, :form_definition)
    end
  end
end
