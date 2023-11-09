class SetLatLonOnPlaces < ActiveRecord::Migration[6.1]
  def up
    GrdaWarehouse::Place.find_in_batches do |batch|
      places = batch.map do |place|
        place.lat = place.lat_lon['lat']
        place.lon = place.lat_lon['lon']
        place.attributes
      end
      GrdaWarehouse::Place.upsert_all(places)
    end
  end
end
