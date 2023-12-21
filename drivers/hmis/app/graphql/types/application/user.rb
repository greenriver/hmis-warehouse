###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::User < Types::BaseObject
    # maps to Hmis::User
    description 'User account for a user of the system'
    graphql_name 'ApplicationUser'
    field :id, ID, null: false
    field :name, String, null: false
    field :email, String, null: false
    field :first_name, String, null: true
    field :last_name, String, null: true
    field :activity_logs, Types::Application::ActivityLog.page_type, null: false
    field :client_access_summaries, Types::Application::ClientAccessSummary.page_type, null: false
    field :enrollment_access_summaries, Types::Application::EnrollmentAccessSummary.page_type, null: false
    field :recent_items, [Types::HmisSchema::OmnisearchResult], null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

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

    def client_access_summaries
      access_denied! unless current_user.can_audit_users?

      object.client_access_summaries
    end

    def enrollment_access_summaries
      access_denied! unless current_user.can_audit_users?

      object.enrollment_access_summaries
    end
  end
end
