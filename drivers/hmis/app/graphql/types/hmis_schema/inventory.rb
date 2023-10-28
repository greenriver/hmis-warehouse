###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Inventory < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    def self.configuration
      Hmis::Hud::Inventory.hmis_configuration(version: '2024')
    end

    hud_field :id, ID, null: false
    hud_field :coc_code, null: true
    hud_field :household_type, HmisSchema::Enums::Hud::HouseholdType, null: true
    hud_field :availability, HmisSchema::Enums::Hud::Availability
    hud_field :unit_inventory, default_value: 0
    hud_field :bed_inventory, default_value: 0
    hud_field :ch_vet_bed_inventory
    hud_field :youth_vet_bed_inventory
    hud_field :vet_bed_inventory
    hud_field :ch_youth_bed_inventory
    hud_field :youth_bed_inventory
    hud_field :ch_bed_inventory
    hud_field :other_bed_inventory
    hud_field :es_bed_type, HmisSchema::Enums::Hud::BedType
    hud_field :inventory_start_date, null: true
    hud_field :inventory_end_date
    field :active, Boolean, null: false
    custom_data_elements_field
  end
end
