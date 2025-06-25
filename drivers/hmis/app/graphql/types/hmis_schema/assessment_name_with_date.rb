###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::AssessmentNameWithDate < Types::BaseObject
    # object is an OpenStruct with the following shape:
    # {
    #   id: ID,
    #   name: String,
    #   date: GraphQL::Types::ISO8601Date,
    # }

    field :id, ID, null: false
    field :name, String, null: false
    field :date, GraphQL::Types::ISO8601Date, null: false
  end
end
