###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class Application::LoginActivity < Types::BaseObject
    # maps to ActivityLog
    graphql_name 'LoginActivity'

    field :id, ID, null: false
    field :login_time, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :ip_address, String, null: true, method: :ip
    field :location_description, String, null: true
  end
end
