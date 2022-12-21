###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Bed < Types::BaseObject
    field :id, ID, null: false
    field :unit, HmisSchema::Unit, null: false
    field :bed_type, Types::HmisSchema::Enums::InventoryBedType, null: false
    field :name, String, null: true
    field :gender, String, null: true
    field :start_date, GraphQL::Types::ISO8601Date, null: false
    field :end_date, GraphQL::Types::ISO8601Date, null: true

    def unit
      load_ar_association(object, :unit)
    end
  end
end
