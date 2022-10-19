###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Inventory < Types::BaseObject
    include Types::Concerns::HasFields

    def self.configuration
      Hmis::Hud::Inventory.hmis_configuration(version: '2022')
    end

    def self.type_fields
      {
        id: {
          field: { type: ID, null: false },
        },
        project: {
          field: { type: Types::HmisSchema::Project },
          argument: { name: :project_id, type: ID },
        },
        coc_code: {
          field: { type: String },
          argument: {},
        },
        household_type: {
          field: { type: HmisSchema::Enums::HouseholdType },
          argument: {},
        },
        availability: {
          field: { type: HmisSchema::Enums::Availability },
          argument: {},
        },
        unit_inventory: {
          field: {},
          argument: {},
        },
        bed_inventory: {
          field: {},
          argument: {},
        },
        ch_vet_bed_inventory: {
          field: {},
          argument: {},
        },
        youth_vet_bed_inventory: {
          field: {},
          argument: {},
        },
        vet_bed_inventory: {
          field: {},
          argument: {},
        },
        ch_youth_bed_inventory: {
          field: {},
          argument: {},
        },
        youth_bed_inventory: {
          field: {},
          argument: {},
        },
        ch_bed_inventory: {
          field: {},
          argument: {},
        },
        other_bed_inventory: {
          field: {},
          argument: {},
        },
        es_bed_type: {
          field: { type: HmisSchema::Enums::BedType },
          argument: {},
        },
        inventory_start_date: {
          field: { null: false },
          argument: {},
        },
        inventory_end_date: {
          field: {},
          argument: {},
        },
        date_created: {
          field: {},
        },
        date_updated: {
          field: {},
        },
        date_deleted: {
          field: {},
        },
      }.freeze
    end

    add_fields
  end
end
