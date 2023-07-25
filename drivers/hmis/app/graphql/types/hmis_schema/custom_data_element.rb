###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CustomDataElement < Types::BaseObject
    field :id, ID, null: false
    field :key, String, null: false
    field :field_type, HmisSchema::Enums::CustomDataElementType, null: false
    field :label, String, null: false
    field :repeats, Boolean, null: false
    field :at_occurrence, Boolean, null: false
    field :value, HmisSchema::CustomDataElementValue, null: true, extras: [:parent]
    field :values, [HmisSchema::CustomDataElementValue], null: true, extras: [:parent]

    # object is a CustomDataElementDefinition
    # parent is the parent (Enrollment, Client, etc)

    # If this custom element only allows one value, 'value' is set
    def value(parent:)
      return if object.repeats

      load_ar_association(object, :values, scope: parent.custom_data_elements)&.first
    end

    # If this custom element allows multiple values, 'values' is set (repeats: true)
    def values(parent:)
      return unless object.repeats

      load_ar_association(object, :values, scope: parent.custom_data_elements)
    end
  end
end
