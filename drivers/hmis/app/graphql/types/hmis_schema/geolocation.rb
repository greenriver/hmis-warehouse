###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Geolocation < Types::BaseObject
    field :id, ID, null: false
    field :coordinates, HmisSchema::GeolocationCoordinates, null: true
    field :collected_by, String, null: true

    # dates and times - todo remove what we dont need
    field :located_on, GraphQL::Types::ISO8601Date, null: true
    field :located_at, GraphQL::Types::ISO8601DateTime, null: true
    field :processed_at, GraphQL::Types::ISO8601DateTime, null: true
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false

    # todo add project name? via source.project.name

    def coordinates
      # self-- needs to be nested under coordinates to work... because thats the field_name on the form
      object
    end
  end
  # backed by ClientLocationHistory::Location
end
