###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Inventory < Types::BaseObject
    include Types::Concerns::HasFields

    def self.type_fields
      {
        id: {
          field: { type: ID, null: false },
        },
        project: {
          field: { type: Types::HmisSchema::Project, null: false },
          argument: { name: :project_id, type: ID, required: false },
        },
        coc_code: {
          field: { type: String, null: false },
          argument: { required: false },
        },
        household_type: {
          field: { type: HmisSchema::Enums::HouseholdType, null: false },
          argument: { required: false },
        },
        availability: {
          field: { type: HmisSchema::Enums::Availability, null: true },
          argument: { required: false },
        },
        unit_inventory: {
          field: { type: Integer, null: false },
          argument: { required: false },
        },
        bed_inventory: {
          field: { type: Integer, null: false },
          argument: { required: false },
        },
        ch_vet_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        youth_vet_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        ch_youth_vet_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        vet_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        ch_youth_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        youth_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        ch_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        other_bed_inventory: {
          field: { type: Integer, null: true },
          argument: { required: false },
        },
        es_bed_type: {
          field: { type: HmisSchema::Enums::BedType, null: true },
          argument: { required: false },
        },
        inventory_start_date: {
          field: { type: GraphQL::Types::ISO8601Date, null: false },
          argument: { required: false },
        },
        inventory_end_date: {
          field: { type: GraphQL::Types::ISO8601Date, null: true },
          argument: { required: false },
        },
        date_created: {
          field: { type: GraphQL::Types::ISO8601DateTime, null: false },
        },
        date_updated: {
          field: { type: GraphQL::Types::ISO8601DateTime, null: false },
        },
        date_deleted: {
          field: { type: GraphQL::Types::ISO8601DateTime, null: true },
        },
      }.freeze
    end

    add_fields
  end
end
