###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferral < Types::BaseObject
    # object is a Hmis::Ce::Referral

    # Similar to Enrollment, this schema class overrides the `field` method
    # and adds a `summary_field` method, to distinguish between fields that can be resolved
    # by those who can_view? vs. just can_view_summary?
    # If user lacks sufficient access, the field will be resolved as null.
    def self.field(name, type = nil, **kwargs)
      # See Types::BaseField `authorized?` function.
      unless kwargs.key?(:authorize_with)
        kwargs[:authorize_with] = lambda do |current_user, object|
          current_user.policy_for(object, policy_type: :ce_referral).can_view?
        end
      end

      super(name, type, **kwargs)
    end

    # No field-level authorization is needed here; we know the user can view the referral summary if it's being resolved at all
    def self.summary_field(name, type = nil, **kwargs)
      field(name, type, **kwargs, authorize_with: nil)
    end

    # Check for most minimal permission needed to resolve this object: either can_view? OR can_view_summary?
    def self.authorized?(object, ctx)
      user = ctx[:current_user]
      policy = user.policy_for(object, policy_type: :ce_referral)
      super && (policy.can_view? || policy.can_view_summary?)
    end

    # Summary fields that anyone who can view the summary of this referral has access to
    summary_field :id, ID, null: false
    summary_field :status, HmisSchema::Enums::CeReferralStatus, null: false
    summary_field :custom_status, HmisSchema::CeCustomReferralStatus, null: true
    summary_field :client_id, ID, null: false
    summary_field :client_name, String, null: true, description: 'The name of the referred client. Always available to those who can view the full referral, even without full client record access.'
    # Special case: Client is a "summary field" because it doesn't require referral visibility, but resolving it does require permission to view the client record.
    summary_field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    summary_field :source_enrollment_id, ID, null: false
    # Resolve project fields separately, instead of on the project schema object, in case user can't view the project
    summary_field :target_project_id, ID, null: false
    summary_field :target_project_name, String, null: false
    summary_field :target_project_type, HmisSchema::Enums::ProjectType, null: false
    summary_field :target_organization_name, String, null: false

    summary_field :referred_by, Application::User, null: true
    summary_field :active, Boolean, null: false, method: :active?

    access_field authorize_with: nil do
      field :can_view_referral_details, Boolean, null: false
      field :can_view_target_project, Boolean, null: false
      field :can_view_source_enrollment_details, Boolean, null: false
    end

    # Detailed fields that only those with full view access should see. Must be nullable
    field :client, Types::HmisSchema::Client, null: true, description: 'The full client record, if the user has permission to view it.'
    field :source_enrollment, Types::HmisSchema::CeReferralSourceEnrollment, null: true, description: 'Limited details about the source enrollment. Available even without full access to the source record.'
    field :opportunity, HmisSchema::CeOpportunity, null: true
    field :steps, [HmisSchema::CeReferralStep], null: true
    field :client_age, Integer, null: true, description: 'The age of the referred client. Always available to those who can view the referral, even without full client record access.'
    field :current_steps, [HmisSchema::CeReferralStep], null: true
    field :days_on_current_steps, Integer, null: true
    field :updated_by, Application::User, null: true
    field :target_enrollment, Types::HmisSchema::Enrollment, null: true, description: 'Target enrollment, if the user has permission to view it.'
    field :swimlanes, [HmisSchema::CeReferralSwimlane], null: true
    field :workflow_template_name, String, null: true
    field :audit_events, HmisSchema::CeReferralAuditEvent.page_type, null: true
    field :notes, HmisSchema::CeReferralNote.page_type, null: true
    # generically resolve current values for any fields referenced by Match Rule expressions
    field :current_match_values, [HmisSchema::CeMatchValue], null: true, description: 'Eligibility-related field values. May expose data beyond normal permissions.', method: :resolve_match_rule_fields

    available_filter_options do
      arg :referral_status, [String]
      arg :project, [ID]
      arg :project_type, [HmisSchema::Enums::ProjectType]
      arg :workflow_template, [String]
      arg :organization, [ID]
      arg :on_current_task_since, GraphQL::Types::ISO8601Date # TODO - we will discuss this with design and probably make updates
    end

    def custom_status
      load_ar_association(object, :custom_status)
    end

    def steps # Don't resolve in batch
      instance = object.workflow_instance
      steps_by_node_id = instance.steps.index_by(&:node_id)

      graph = instance.template.graph(preloads: :inflows) # preload inflows so we can check conditions without n+1
      graph.
        # Stop the search when the node doesn't exist yet and is conditional. We don't want to return this node, or any of its children, if it won't definitely happen.
        walk(stop_when: ->(node) { steps_by_node_id[node.id].nil? && node.conditional_inflows? }).
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

    def client_name
      c = load_ar_association(object, :client)

      # This is a summary field. If the current user can view the referral, always return the client name
      # (even if the current user can't otherwise view that client)
      return c.brief_name.presence || c.masked_name if current_user.policy_for(object, policy_type: :ce_referral).can_view?

      # Otherwise if the current user can only view the referral summary, only return the client name if permissioned
      viewable_client = load_ar_scope(scope: Hmis::Hud::Client.viewable_by(current_user), id: c.id)
      return c.masked_name unless viewable_client
      return c.masked_name unless current_permission?(permission: :can_view_client_name, entity: viewable_client)

      viewable_client.brief_name.presence || viewable_client.masked_name
    end

    # NOTE: This field intentionally does not check can_view_clients
    def client_age
      load_ar_association(object, :client).age
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
      return unless object.target_enrollment_id

      load_ar_scope(scope: Hmis::Hud::Enrollment.viewable_by(current_user), id: object.target_enrollment_id)
    end

    def source_enrollment
      return unless object.source_enrollment_id

      # Resolve source Enrollment without checking viewable_by.This resolves as type CeReferralSourceEnrollment, so it only exposes limited data from the Enrollment
      enrollment = load_ar_association(object, :source_enrollment)

      # Not passing definition_identifiers because we don't need to resolve assessment data in this context (for now)
      OpenStruct.new(enrollment: enrollment, definition_identifiers: [])
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
      source_enrollment = load_ar_scope(scope: Hmis::Hud::Enrollment.viewable_by(current_user), id: object.source_enrollment_id)

      {
        can_view_referral_details: policy_for(object, policy_type: :ce_referral).can_view?,
        can_view_target_project: project.present? && policy_for(project, policy_type: :hmis_project).can_view?,
        can_view_source_enrollment_details: source_enrollment.present?,
      }
    end

    def audit_events
      object.audit_events.
        # Specifically for end_workflow events, only record an audit event for referral acceptance or rejection.
        # Other side effects could be triggered by workflow end (such as creating an enrollment or a CE event), but these don't need to be recorded in the audit table
        where(event_type: 'end_workflow').
        where("event_data->>'message' IN (?)", [Hmis::Ce::ReferralMessageHandler::REJECT_REFERRAL_MESSAGE, Hmis::Ce::ReferralMessageHandler::ACCEPT_REFERRAL_MESSAGE]).
        or(object.audit_events.where(event_type: ['complete_step', 'start_workflow'])).
        order(created_at: :desc)
    end

    def notes
      object.notes.order(created_at: :desc)
    end

    private

    def participants_by_swimlane_id
      @participants_by_swimlane_id ||= object.participants.group_by(&:swimlane_id)
    end
  end
end
