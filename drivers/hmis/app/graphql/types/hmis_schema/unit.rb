###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Unit < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: true
    field :beds, [HmisSchema::Bed], null: false
    field :bed_count, Integer, null: false
    field :start_date, GraphQL::Types::ISO8601Date, null: false
    field :end_date, GraphQL::Types::ISO8601Date, null: true
  end
end
