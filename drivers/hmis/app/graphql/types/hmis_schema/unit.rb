###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Unit < Types::BaseObject
    include Types::HmisSchema::HasBeds

    field :id, ID, null: false
    field :name, String, null: true
    beds_field
    field :start_date, GraphQL::Types::ISO8601Date, null: false
    field :end_date, GraphQL::Types::ISO8601Date, null: true

    def beds(**args)
      resolve_beds(**args)
    end
  end
end
