###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Inventory < Types::BaseObject
    include Types::HmisSchema::HasUnits
    def self.configuration
      Hmis::Hud::Inventory.hmis_configuration(version: '2022')
    end

    hud_field :id, ID, null: false
    hud_field :project, Types::HmisSchema::Project, null: false
    hud_field :coc_code
    hud_field :household_type, HmisSchema::Enums::Hud::HouseholdType
    hud_field :availability, HmisSchema::Enums::Hud::Availability
    hud_field :unit_inventory
    hud_field :bed_inventory
    hud_field :ch_vet_bed_inventory
    hud_field :youth_vet_bed_inventory
    hud_field :vet_bed_inventory
    hud_field :ch_youth_bed_inventory
    hud_field :youth_bed_inventory
    hud_field :ch_bed_inventory
    hud_field :other_bed_inventory
    hud_field :es_bed_type, HmisSchema::Enums::Hud::BedType
    hud_field :inventory_start_date, null: false
    hud_field :inventory_end_date
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted
    field :active, Boolean, null: false
    units_field

    def units(**args)
      resolve_units(**args)
    end
  end
end
