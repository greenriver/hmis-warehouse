###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Funder < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    def self.configuration
      Hmis::Hud::Funder.hmis_configuration(version: '2022')
    end

    hud_field :id, ID, null: false
    hud_field :project, Types::HmisSchema::Project, null: false
    hud_field :funder, HmisSchema::Enums::Hud::FundingSource
    hud_field :other_funder
    hud_field :grant_id
    hud_field :start_date, null: false
    hud_field :end_date
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :user, HmisSchema::User, null: true
    field :active, Boolean, null: false
    custom_data_elements_field
  end
end
