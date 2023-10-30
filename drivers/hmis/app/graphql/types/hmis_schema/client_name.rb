###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ClientName < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

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

    # Object is a Hmis::Hud::CustomClientName

    def id
      return object.id if object.persisted?

      # Placeholder ID for unpersisted primary name based on Client attributes.
      # Use personal ID so its unique in the cache.
      "#{object.personal_id}-primary"
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
