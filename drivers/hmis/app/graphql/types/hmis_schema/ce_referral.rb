###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferral < Types::BaseObject
    field :id, ID, null: false
    field :opportunity, HmisSchema::CeOpportunity, null: false
    field :steps, [HmisSchema::CeReferralStep], null: false
    field :status, HmisSchema::Enums::CeReferralStatus, null: false
    field :client, Types::HmisSchema::Client, null: false

    def steps
      instance = object.workflow_instance
      steps_by_node_id = instance.steps.index_by(&:node_id)
      instance.template.graph.walk.filter(&:task?).map do |node|
        steps_by_node_id[node.id] || instance.steps.new(node: node).freeze
      end
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
