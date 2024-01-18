###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ScanCardCode < Types::BaseObject
    field :id, ID, null: false
    field :code, ID, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :created_by, Types::Application::User, null: true
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true, method: :deleted_at
    field :deleted_by, Types::Application::User, null: true
  end
end