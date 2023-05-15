###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomDataElement < Types::BaseObject
    # object is an OpenStruct, see HasCustomDataElements

    field :id, ID, null: false
    field :key, String, null: true
    field :label, String, null: true
    field :repeats, Boolean, null: false
    field :value, HmisSchema::CustomDataElementValue, null: true
    field :values, [HmisSchema::CustomDataElementValue], null: true

    # If this custom element only allows one value, 'value' is set
    def value
      return if object.repeats

      object.values&.first
    end

    # If this custom element allows multiple values, 'values' is set (repeats: true)
    def values
      return unless object.repeats

      object.values || []
    end
  end
end
