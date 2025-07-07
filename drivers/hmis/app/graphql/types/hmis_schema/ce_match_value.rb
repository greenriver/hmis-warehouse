###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeMatchValue < Types::BaseObject
    # object is an OpenStruct
    # used to generically resolve Key-value pairs for fields referenced by Match Rule expressions

    field :id, ID, null: false, description: 'Unique identifier for this match value'
    field :rule_id, ID, null: false
    field :rule_name, String, null: false
    field :field_name, String, null: false, description: 'Name of this field'
    field :field_value, String, null: true, description: 'String representation of the value for this field'

    def id
      "#{object.rule_id}-#{object.field_name}"
    end
  end
end
