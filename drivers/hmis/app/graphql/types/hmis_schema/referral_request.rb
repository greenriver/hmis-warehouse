###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Types
  class HmisSchema::ReferralRequest < Types::BaseObject
    field :id, ID, null: false
    field :identifier, ID, null: false
    field :requested_on, GraphQL::Types::ISO8601DateTime, null: false
    field :unit_type, HmisSchema::UnitTypeObject, null: false
    field :needed_by, GraphQL::Types::ISO8601Date, null: false
    field :requestor_name, String, null: false
    field :requestor_phone, String, null: false
    field :requestor_email, String, null: false

    def unit_type
      load_ar_association(object, :unit_type)
    end
  end
end
