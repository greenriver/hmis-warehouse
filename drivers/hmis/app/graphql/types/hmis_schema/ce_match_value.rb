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

    # logic to implement:
    # 1. Find all ce_match_rules (or expressions logged somewhere?) that were applicable at the time what this referral was created
    # 2. For each expression, resolve it into a set of referenced fields
    # 3. For each field, evaluate it against this client (really, their destination client) using the FieldMap
    # 4. For each field, translate the field name into a human-readable name (using CDE Label if appropriate)
    # 5. Resolve key-value pairs in an array on the CeReferral type (put on the Referral model, probably)

    field :id, ID, null: false
    field :field_name, String, null: false, description: 'Name of this field'
    field :field_value, String, null: true, description: 'String representation of the value for this field'
  end
end
