###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Adapter class for resolving CustomDataElementDefinition ("cded") and CustomDataElements.
# Resolved as Types::HmisSchema::CustomDataElement
module Hmis::Hud
  GraphqlCdeValueAdapter = Struct.new(:definition, :custom_data_elements, keyword_init: true) do
    delegate(:key, :field_type, :label, :repeats, to: :definition)

    # Unique ID for caching based on values
    def id
      [definition.id, *custom_data_elements.map(&:id)].join(':')
    end

    # If this custom element allows multiple values, 'values' is set (repeats: true)
    def values
      definition.repeats ? custom_data_elements : nil
    end

    # If this custom element only allows one value, 'value' is set
    def value
      definition.repeats ? nil : custom_data_elements&.first
    end

    # Resolves as Types::HmisSchema::Enums::DisplayHook
    def display_hooks
      hooks = []
      hooks << 'TABLE_SUMMARY' if definition.show_in_summary
      hooks
    end
  end
end
