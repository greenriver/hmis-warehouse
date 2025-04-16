class RenameClientGeolocationsView < ActiveRecord::Migration[7.0]
  def change
    # Drop the view that had incorrect name
    drop_view :analytics_client_geolocations, revert_to_version: 2

    # Update the correctly named view to the new version
    replace_view 'analytics.client_geolocations', version: 2, revert_to_version: 1
  end
end
