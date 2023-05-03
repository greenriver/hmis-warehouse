###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientContactPoint < Types::BaseObject
    field :value, String, null: true
    field :notes, String, null: true
    field :use, HmisSchema::Enums::ClientContactPointUse
    field :system, HmisSchema::Enums::ClientContactPointSystem
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    # Object is a Hmis::Hud::CustomClientContactPoint
  end
end
