###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::GeolocationCoordinates < Types::BaseObject
    field :id, ID, null: false
    # non-nullable because clh_locations with null lat/lon should be filtered out before resolving
    field :latitude, String, null: false, method: :lat
    field :longitude, String, null: false, method: :lon
  end
  # backed by ClientLocationHistory::Location
end
