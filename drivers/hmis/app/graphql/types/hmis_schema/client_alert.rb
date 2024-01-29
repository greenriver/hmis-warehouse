###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientAlert < Types::BaseObject
    description 'Alert'
    field :id, ID, null: false
    field :note, String, null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :created_by, Types::Application::User, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :priority, HmisSchema::Enums::ClientAlertPriorityLevel, null: false, default_value: Hmis::ClientAlert::LOW
  end
end
