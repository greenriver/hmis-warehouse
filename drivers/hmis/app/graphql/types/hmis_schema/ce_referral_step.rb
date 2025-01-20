###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralStep < Types::BaseObject
    field :id, ID, null: false
    field :form_definition, Types::Forms::FormDefinition, null: false
    field :name, String, null: false
    field :status, String, null: false
    delegate :name, :form_definition, to: :workflow_node

    def id
      # sometimes object is not yet persisted
      "#{object.node_id}:#{object.instance_id}"
    end

    def workflow_node
      object.node
    end
  end
end
