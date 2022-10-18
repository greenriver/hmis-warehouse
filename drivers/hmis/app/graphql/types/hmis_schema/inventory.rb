###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Inventory < Types::BaseObject
    description 'HUD Inventory'
    field :id, ID, null: false
    field :project, Types::HmisSchema::Project, null: false
    field :coc_code, String, null: false
    field :household_type, HmisSchema::Enums::HouseholdType, null: false
    field :availability, HmisSchema::Enums::Availability, null: true
    field :unit_inventory, Float, null: false
    field :bed_inventory, Float, null: false
    field :ch_vet_bed_inventory, Float, null: true
    field :youth_vet_bed_inventory, Float, null: true
    field :ch_youth_vet_bed_inventory, Float, null: true
    field :vet_bed_inventory, Float, null: true
    field :ch_youth_bed_inventory, Float, null: true
    field :youth_bed_inventory, Float, null: true
    field :ch_bed_inventory, Float, null: true
    field :other_bed_inventory, Float, null: true
    field :es_bed_type, HmisSchema::Enums::BedType, null: true
    field :inventory_start_date, GraphQL::Types::ISO8601Date, null: false
    field :inventory_end_date, GraphQL::Types::ISO8601Date, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
  end
end
