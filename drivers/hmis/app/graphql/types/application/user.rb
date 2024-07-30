###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::User < Types::BaseObject
    include Types::HmisSchema::HasAuditHistory
    include Hmis::Concerns::HmisArelHelper

    # maps to Hmis::User
    description 'User account for a user of the system'
    graphql_name 'ApplicationUser'
    field :id, ID, null: false
    field :name, String, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true

    # activity_logs is for auditing entities that this user has accessed/viewed.
    # It's based on every GraphQL query that was made, but the raw data is not useful to show end users
    field :activity_logs, Types::Application::ActivityLog.page_type, null: false

    # client_access_summaries and enrollment_access_summaries are both downstream from hmis_activity_logs table;
    # the Hmis::ActivityLogProcessorJob populates these views so that the data is more readable by end users.
    field :client_access_summaries, Types::Application::ClientAccessSummary.page_type, null: false do
      argument(:filters, Types::Application::ClientAccessSummary.filter_options_type, required: false)
    end
    field :enrollment_access_summaries, Types::Application::EnrollmentAccessSummary.page_type, null: false do
      argument(:filters, Types::Application::EnrollmentAccessSummary.filter_options_type, required: false)
    end

    field :recent_items, [Types::HmisSchema::OmnisearchResult], null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    field :staff_assignments, HmisSchema::StaffAssignment.page_type, null: true

    # audit_history returns the changes this user has made (as opposed to activity_logs which is just views, not edits).
    # We use the generic term 'audit' to encompass both types of history (view and edit), but many places in the code,
    # 'audit' just refers to edit history.
    audit_history_field(
      excluded_keys: Types::HmisSchema::Enrollment::EXCLUDED_KEYS_FOR_AUDIT,
      # filter_args: { type_name: 'UserAuditEvent' },
      filter_args: { type_name: 'UserAuditEvent', omit: [:user] },
    )

    EXCLUDED_RECORD_TYPES_FOR_AUDIT = ['Hmis::Wip'].freeze

    def audit_history(filters: nil)
      v_t = GrdaWarehouse.paper_trail_versions.arel_table
      scope = GrdaWarehouse.paper_trail_versions.
        where(true_user_id: object.id).
        where.not(v_t[:enrollment_id].eq(nil).and(v_t[:client_id].eq(nil)).and(v_t[:project_id].eq(nil))).
        where.not(object_changes: nil, event: 'update').
        where.not(item_type: EXCLUDED_RECORD_TYPES_FOR_AUDIT).
        unscope(:order). # Unscope to remove default order, otherwise it will conflict
        order(created_at: :desc)
      Hmis::Filter::PaperTrailVersionFilter.new(filters).filter_scope(scope)
    end

    available_filter_options do
      arg :search_term, String
    end

    def name
      object.full_name || "User #{object.id}"
    end

    def recent_items
      # Only allow this if fetching our own recent items
      return [] unless current_user == object

      current_user.recent_items
    end

    def activity_logs
      access_denied! unless current_user.can_audit_users?

      object.activity_logs
    end

    def client_access_summaries(filters: nil)
      access_denied! unless current_user.can_audit_users?

      Hmis::ClientAccessSummary.order(last_accessed_at: :desc, client_id: :desc).
        apply_filter(user: object, starts_on: filters&.on_or_after, search_term: filters&.search_term)
    end

    def enrollment_access_summaries(filters: nil)
      access_denied! unless current_user.can_audit_users?

      Hmis::EnrollmentAccessSummary.order(last_accessed_at: :desc, enrollment_id: :desc).
        apply_filter(
          user: object,
          starts_on: filters&.on_or_after,
          search_term: filters&.search_term,
          project_ids: filters&.project,
        )
    end

    def staff_assignments
      # n+1 queries, needs optimization to be performant on collections
      object.staff_assignments.
        joins(:household).
        order(
          hh_t[:any_wip].eq(true).desc,
          hh_t[:latest_exit].eq(nil).desc,
          earliest_entry: :desc,
          id: :desc,
        )
    end
  end
end
