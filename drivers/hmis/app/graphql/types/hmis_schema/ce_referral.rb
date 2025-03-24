###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferral < Types::BaseObject
    # object is a Hmis::Ce::Referral
    field :id, ID, null: false
    field :opportunity, HmisSchema::CeOpportunity, null: false
    field :steps, [HmisSchema::CeReferralStep], null: false
    field :status, HmisSchema::Enums::CeReferralStatus, null: false
    field :client_id, ID, null: false
    field :client, Types::HmisSchema::Client, null: true
    field :date_started, GraphQL::Types::ISO8601Date, null: false, method: :created_at
    field :current_step, Types::HmisSchema::CeReferralStep, null: true

    available_filter_options do
      arg :status, [HmisSchema::Enums::CeReferralStatus]
    end

    def steps
      instance = object.workflow_instance
      steps_by_node_id = instance.steps.index_by(&:node_id)

      graph = instance.template.graph(preloads: :inflows) # preload inflows so we can check conditions without n+1
      graph.
        # Stop the search when the node doesn't exist yet and is conditional. We don't want to return this node, or any of its children, if it won't definitely happen.
        walk(stop_when: ->(node) { steps_by_node_id[node.id].nil? && node.conditional_inflows? }).
        filter(&:task?).
        map do |node|
        next steps_by_node_id[node.id] if steps_by_node_id[node.id] # task instance already exists

        next nil if node.conditional_inflows? # task is conditional, don't show it yet

        # initialize step to display in the UI
        instance.steps.new(node: node).freeze
      end.compact
    end

    def client
      load_ar_association(object, :client, scope: Hmis::Hud::Client.viewable_by(current_user))
    end

    def current_step
      instance = load_ar_association(object, :workflow_instance)
      steps = load_ar_association(instance, :steps, scope: Hmis::WorkflowExecution::Step.where(status: ['available', 'in_progress']))
      steps.first # There can be multiple steps currently in progress, but we're only going to show one in the project referrals table
    end

    def opportunity
      load_ar_association(object, :opportunity)
    end
  end
end
