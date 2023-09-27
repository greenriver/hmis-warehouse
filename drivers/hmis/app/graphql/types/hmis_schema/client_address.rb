###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientAddress < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    field :id, ID, null: false
    field :line1, String, null: true
    field :line2, String, null: true
    field :city, String, null: true
    field :state, String, null: true
    field :district, String, null: true
    field :country, String, null: true
    field :postal_code, String, null: true
    field :notes, String, null: true
    field :use, HmisSchema::Enums::ClientAddressUse
    field :address_type, HmisSchema::Enums::ClientAddressType
    field :client, HmisSchema::Client, null: false

    # Object is a Hmis::Hud::CustomClientAddress

    def client
      load_ar_association(object, :client)
    end
  end
end
