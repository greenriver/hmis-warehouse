###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectCoc < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::ProjectCoc.hmis_configuration(version: '2024')
    end

    hud_field :id, ID, null: false
    hud_field :coc_code, null: true
    hud_field :geocode, null: true
    hud_field :address1
    hud_field :address2
    hud_field :city
    hud_field :state
    hud_field :zip
    hud_field :geography_type, HmisSchema::Enums::Hud::GeographyType
  end
end
