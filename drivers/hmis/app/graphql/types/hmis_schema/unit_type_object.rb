###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::UnitTypeObject < Types::BaseObject
    field :id, ID, null: false
    field :description, String, null: true
    field :bed_type, Types::HmisSchema::Enums::InventoryBedType, null: true
    field :unit_size, Integer, null: true
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
  end
end
