###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ProjectCoc < Types::BaseObject
    def self.configuration
      Hmis::Hud::ProjectCoc.hmis_configuration(version: '2022')
    end

    hud_field :id, ID, null: false
    hud_field :project, Types::HmisSchema::Project, null: false
    hud_field :coc_code
    hud_field :geocode
    hud_field :address1
    hud_field :address2
    hud_field :city
    hud_field :state
    hud_field :zip
    hud_field :geography_type, HmisSchema::Enums::Hud::GeographyType
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
  end
end
