###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::File < Types::BaseObject
    description 'File'
    field :id, ID, null: false
    field :content_type, String, null: false
    field :effective_date, GraphQL::Types::ISO8601Date, null: true
    field :expiration_date, GraphQL::Types::ISO8601Date, null: true
    field :updated_at, GraphQL::Types::ISO8601Date, null: true
    field :created_at, GraphQL::Types::ISO8601Date, null: true
    field :url, String, null: false
  end
end
