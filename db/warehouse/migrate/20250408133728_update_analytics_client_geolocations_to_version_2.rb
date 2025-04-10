# frozen_string_literal: true

class UpdateAnalyticsClientGeolocationsToVersion2 < ActiveRecord::Migration[7.0]
  def change
    replace_view :analytics_client_geolocations, version: 2, revert_to_version: 1
  end
end
