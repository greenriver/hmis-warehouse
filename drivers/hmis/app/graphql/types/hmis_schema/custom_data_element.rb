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
    field :value, HmisSchema::CustomDataElementValue, null: true
    field :values, [HmisSchema::CustomDataElementValue], null: true

    # object is a Hmis::Hud::GraphqlCdeValueAdapter

    def activity_log_object_identity
      object.id
    end
  end
end
