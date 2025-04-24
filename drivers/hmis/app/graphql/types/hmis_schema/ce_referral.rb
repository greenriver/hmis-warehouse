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

    # Resolve project fields separately, instead of the whole project object, in case user can't view the project
    field :target_project_id, ID, null: false
    field :target_project_name, String, null: false
    field :target_project_type, HmisSchema::Enums::ProjectType, null: false

    field :referred_by, Application::User, null: true
    field :active, Boolean, null: false, method: :active?

    available_filter_options do
      arg :status, [HmisSchema::Enums::CeReferralStatus]
      arg :project, [ID]
      arg :project_type, [HmisSchema::Enums::ProjectType]
    end

    def steps # Not resolved in batch
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
      # TODO(#7573) - fix n+1, see commented out test in drivers/hmis/spec/requests/hmis/ce/project_ce_referrals_spec.rb
      Hmis::Hud::Client.viewable_by(current_user).find_by(id: object.client_id)
    end

    def current_step_name
      step = load_ar_association(object, :current_step)
      return if step.nil?

      load_ar_association(step, :node)&.name
    end

    def opportunity
      load_ar_association(object, :opportunity)
    end

    def target_project_id
      load_ar_association(object, :opportunity).project_id
    end

    def target_project_name
      load_ar_association(object, :target_project).project_name
    end

    def target_project_type
      load_ar_association(object, :target_project).project_type
    end

    def referred_by
      load_ar_association(object, :referred_by)
    end
  end
end
