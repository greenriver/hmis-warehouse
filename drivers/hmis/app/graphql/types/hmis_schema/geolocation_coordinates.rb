###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::GeolocationCoordinates < Types::BaseObject
    field :id, ID, null: false
    field :latitude, String, null: true, method: :lat
    field :longitude, String, null: true, method: :lon
  end
  # backed by ClientLocationHistory::Location
end
