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
    field :expiration_date, GraphQL::Types::ISO8601DateTime, null: true
    field :severity, String, null: true

    def client
      load_ar_association(object, :client)
    end
  end
end
