###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientAddress < Types::BaseObject
    field :line1, String, null: true
    field :line2, String, null: true
    field :city, String, null: true
    field :state, String, null: true
    field :district, String, null: true
    field :country, String, null: true
    field :postal_code, String, null: true
    field :notes, String, null: true
    field :use, HmisSchema::Enums::ClientAddressUse
    field :type, HmisSchema::Enums::ClientAddressType
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    # Object is a Hmis::Hud::CustomClientAddress
  end
end
