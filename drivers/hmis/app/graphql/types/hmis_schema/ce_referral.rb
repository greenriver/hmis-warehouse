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

    field :current_steps, [HmisSchema::CeReferralStep], null: true
    field :days_on_current_steps, Integer, null: true
    field :updated_by, Application::User, null: true
    field :target_enrollment, Types::HmisSchema::Enrollment, null: true
    field :swimlanes, [HmisSchema::CeReferralSwimlane], null: false
    field :workflow_template_name, String, null: true
    field :audit_events, HmisSchema::CeReferralAuditEvent.page_type, null: false

    # Resolve project fields separately, instead of the whole project object, in case user can't view the project
    field :target_project_id, ID, null: false
    field :target_project_name, String, null: false
    field :target_project_type, HmisSchema::Enums::ProjectType, null: false
    field :target_organization_name, String, null: false

    field :referred_by, Application::User, null: true
    field :active, Boolean, null: false, method: :active?

    access_field do
      field :can_view_target_project, Boolean, null: false
    end

    available_filter_options do
      arg :status, [HmisSchema::Enums::CeReferralStatus]
      arg :project, [ID]
      arg :project_type, [HmisSchema::Enums::ProjectType]
      arg :workflow_template, [String]
      arg :organization, [ID]
      arg :on_current_task_since, GraphQL::Types::ISO8601Date # TODO - we will discuss this with design and probably make updates
    end

    def steps # Don't resolve in batch
      instance = object.workflow_instance
      steps_by_node_id = instance.steps.index_by(&:node_id)

      graph = instance.template.graph(preloads: :inflows) # preload inflows so we can check conditions without n+1
      graph.
        # Stop the search when the node doesn't exist yet and is conditional. We don't want to return this node, or any of its children, if it won't definitely happen.
        walk(stop_when: ->(node) { steps_by_node_id[node.id].nil? && node.conditional_inflows? }).
        filter(&:task?).
        filter(&:user_task?).
        map do |node|
        next steps_by_node_id[node.id] if steps_by_node_id[node.id] # task instance already exists

        next nil if node.conditional_inflows? # task is conditional, don't show it yet

        # initialize step to display in the UI
        step = instance.steps.new(node: node).freeze

        # If the step is unpersisted, assignees won't be persisted yet either,
        # but we know the step's default assignees based on the referral participants, so return them
        participants_by_swimlane_id[node.swimlane_id]&.each do |p|
          step.assignments.new(user: p.user)
        end

        step
      end.compact
    end

    def client
      load_ar_scope(scope: Hmis::Hud::Client.viewable_by(current_user), id: object.client_id)
    end

    def current_steps
      load_ar_association(object, :current_steps).sort_by { |step| [step.available_at, step.id] }
    end

    def days_on_current_steps
      # If there are multiple open steps, use the one that has been available longest
      oldest_open_step = load_ar_association(object, :current_steps).to_a.min_by(&:available_at)
      return nil if oldest_open_step.nil?

      # How many days ago this step was made available
      (Date.current - oldest_open_step.available_at.to_date).to_i
    end

    def updated_by
      # TODO(#7678): Add updated_by as a field to the referral table, and use that directly here
      most_recently_updated_step = load_ar_association(object, :current_steps).to_a.max_by(&:updated_at)

      # If a step was updated more recently than the referral record itself, return the user who updated that step
      if most_recently_updated_step.present? && most_recently_updated_step.updated_at > object.updated_at
        load_last_user_from_versions(most_recently_updated_step)
      else
        load_last_user_from_versions(object)
      end
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

    def target_organization_name
      project = load_ar_association(object, :target_project)
      load_ar_association(project, :organization).name
    end

    def target_enrollment
      enrollment = load_ar_association(object, :target_enrollment)
      return nil unless enrollment.present?

      load_ar_scope(scope: Hmis::Hud::Enrollment.viewable_by(current_user), id: enrollment.id)
    end

    def referred_by
      load_ar_association(object, :referred_by)
    end

    def swimlanes # Don't resolve `swimlanes` in batch on many referrals.
      # First fetch all the users associated with this referral, to avoid n+1 when there are many participants on a referral.
      user_ids = object.participants.map(&:user_id).uniq
      users_by_id = Hmis::User.where(id: user_ids).index_by(&:id)

      object.swimlanes.map do |swimlane|
        # For this swimlane, get all associated participants, and map to the user objects that were already fetched
        participants = (participants_by_swimlane_id[swimlane.id] || []).filter_map do |participant|
          users_by_id[participant.user_id]
        end

        OpenStruct.new(
          id: swimlane.id,
          name: swimlane.name,
          participants: participants,
        )
      end
    end

    def workflow_template_name
      load_ar_association(object, :workflow_template)&.name
    end

    def access
      project_id = load_ar_association(object, :opportunity).project_id
      project = load_ar_scope(scope: Hmis::Hud::Project.viewable_by(current_user), id: project_id)

      {
        can_view_target_project: project.present?,
      }
    end

    def audit_events
      object.audit_events.
        where(event_type: ['complete_step', 'start_workflow', 'end_workflow']).
        order(created_at: :desc)
    end

    private

    def participants_by_swimlane_id
      @participants_by_swimlane_id ||= object.participants.group_by(&:swimlane_id)
    end
  end
end
