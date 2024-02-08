###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientContactPoint < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    field :id, ID, null: false
    field :value, String, null: true
    field :notes, String, null: true
    field :use, HmisSchema::Enums::ClientContactPointUse
    field :system, HmisSchema::Enums::ClientContactPointSystem
    field :client, HmisSchema::Client, null: false

    # Object is a Hmis::Hud::CustomClientContactPoint

    def client
      load_ar_association(object, :client)
    end
  end
end
