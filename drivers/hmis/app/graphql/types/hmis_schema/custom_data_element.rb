###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
    field :display_hooks, [HmisSchema::Enums::DisplayHook], null: false, description: 'Where to display the custom field in the application'
    field :value, HmisSchema::CustomDataElementValue, null: true
    field :values, [HmisSchema::CustomDataElementValue], null: true

    # object is an OpenStruct, see HasCustomDataElements concern for shape

    # Unique ID based on values
    def id
      [object.id, *object.values.map(&:id)].join(':')
    end

    # If this custom element allows multiple values, 'values' is set (repeats: true)
    def values
      object.repeats ? object.values : nil
    end

    # If this custom element only allows one value, 'value' is set
    def value
      object.repeats ? nil : object.values&.first
    end

    def activity_log_object_identity
      object.id
    end

    def display_hooks
      hooks = []
      hooks << 'TABLE_SUMMARY' if object.show_in_summary
      hooks
    end
  end
end
