###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :current_step_name, String, null: true
    field :target_enrollment, Types::HmisSchema::Enrollment, null: true # Don't resolve in batch

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

    def current_step_name # There can be multiple steps currently in progress, but we're only going to show one in the project referrals table
      instance = load_ar_association(object, :workflow_instance)

      step_t = Hmis::WorkflowExecution::Step.arel_table
      step_scope = Hmis::WorkflowExecution::Step.
        where(status: ['available', 'in_progress']).
        # Prefer to return a step that is in_progress over available
        order(Arel::Nodes::Case.new.when(step_t[:status].eq('in_progress')).then(1).else(2)).
        order(step_t[:id]) # Also sort by ID, to make sure this resolves deterministically

      step = load_ar_association(instance, :steps, scope: step_scope).first
      return if step.nil?

      load_ar_association(step, :node)&.name
    end

    def opportunity
      load_ar_association(object, :opportunity)
    end
  end
end
