###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientName < Types::BaseObject
    field :id, ID, null: false
    field :first, String
    field :middle, String
    field :last, String
    field :suffix, String
    hud_field :name_data_quality, Types::HmisSchema::Enums::Hud::NameDataQuality
    field :use, HmisSchema::Enums::ClientNameUse
    field :notes, String
    field :primary, Boolean
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true

    # Object is a Hmis::Hud::CustomClientName
  end
end
