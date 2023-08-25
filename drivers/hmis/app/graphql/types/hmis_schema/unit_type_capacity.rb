###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::UnitTypeCapacity < Types::BaseObject
    field :id, ID, null: false
    field :unit_type, String, null: false
    field :capacity, Integer, null: false
    field :availability, Integer, null: false

    # object is an OpenStruct
  end
end
