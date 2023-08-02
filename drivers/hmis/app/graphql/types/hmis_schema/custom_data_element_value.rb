###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomDataElementValue < Types::BaseObject
    field :id, ID, null: false
    field :value_float, Float, null: true
    field :value_integer, Integer, null: true
    field :value_boolean, Boolean, null: true
    field :value_string, String, null: true
    field :value_text, String, null: true
    field :value_date, GraphQL::Types::ISO8601Date, null: true
    field :value_json, Types::JsonObject, null: true

    ar_field :user, HmisSchema::User, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
  end
end
