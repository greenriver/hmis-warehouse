###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::ActivityLog < Types::BaseObject
    # maps to Hmis::ActivityLog
    graphql_name 'ActivityLog'
    field :id, ID, null: false
    field :user, Types::Application::User, null: false
    field :ip_address, String, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :resolved_records, [Types::Application::ActivityLogRecord], null: false

    def user
      load_ar_association(object, :user)
    end

    def resolved_records
      object.resolved_fields.keys.map do |key|
        record_type, record_id = key.split('/', 2)
        next unless record_type && record_id

        OpenStruct.new(
          record_type: record_type,
          record_id: record_id,
        )
      end.compact
    end
  end
end
