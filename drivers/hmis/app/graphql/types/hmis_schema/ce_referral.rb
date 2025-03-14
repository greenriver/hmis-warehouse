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

      graph = instance.template.graph(preloads: :inflows) # preload inflows so we can check conditions without n+1
      graph.
        # Stop the search when the node doesn't exist yet and is conditional. We don't want to return this node, or any of its children, if it won't definitely happen.
        walk(stop_when: ->(node) { steps_by_node_id[node.id].nil? && node.inflows.map(&:condition).any? }).
        filter(&:task?).
        map do |node|
        # If this node exists already, return it; otherwise, return a non-persisted version, ONLY IF it has no conditionals (will definitely happen).
        steps_by_node_id[node.id] || (node.inflows.map(&:condition).any? ? nil : instance.steps.new(node: node).freeze)
      end.compact
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
