###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Place < GrdaWarehouseBase
    include NotifierConfig

    belongs_to :shape_zip_code, class_name: 'GrdaWarehouse::Shape::ZipCode', primary_key: 'zcta5ce10', foreign_key: 'zipcode', optional: true
    belongs_to :shape_state, class_name: 'GrdaWarehouse::Shape::State', primary_key: 'name', foreign_key: 'state', optional: true
    belongs_to :cls, class_name: 'ClientLocationHistory::Location', primary_key: [:lat, :lon], foreign_key: [:lat, :lon], optional: true

    scope :with_shape_cocs, -> do
      joins('inner join shape_cocs on ST_Within(ST_SetSRID(ST_Point(places.lon, places.lat), 4326), shape_cocs.geom)')
    end

    def self.lookup_lat_lon(query: nil, city: nil, state: nil, postalcode: nil, country: 'us')
      place = lookup(query: query, city: city, state: state, postalcode: postalcode, country: country)&.lat_lon
      [place.try(:[], 'lat'), place.try(:[], 'lon'), place.try(:[], 'bounds')]
    end

    def self.lookup(query: nil, city: nil, state: nil, postalcode: nil, country: 'us')
      key = "#{query}/#{city}/#{state}/#{postalcode}/#{country}"

      @places ||= {}
      place = @places[key] # Look in memory cache
      place = @places[key] = Place.find_by(location: key) if place.blank? # Look in database
      if place.blank?
        return if Rails.cache.read(['Nominatim', 'API PAUSE'])

        place = @places[key] = begin
          # we see a ton of missing zeros at the beginning of zipcodes, store what we have, but lookup the correct value
          nr = nominatim_lookup(query, city, state, postalcode&.rjust(5, '0'), country)
          if nr.present?
            lat = nr.coordinates.first
            lon = nr.coordinates.last
            lat_lon = { lat: lat, lon: lon, bounds: nr.boundingbox }.with_indifferent_access
            Place.create!(
              location: key,
              lat_lon: lat_lon,
              lat: lat,
              lon: lon,
              city: nr.town,
              state: nr.state,
              zipcode: nr.postal_code,
            )
          end
        end
      end
      place
    rescue StandardError => e
      # Sometimes it just dies, that sends Sentry a bunch of errors we can't do anything about, so just eat them
      return if nr.is_a?(Geocoder::Result::Nominatim) && nr.data.try(:[], 'title') == '500 Internal Server Error'

      send_single_notification("Error contacting the OSM Nominatim API.: #{e.message}", 'NominatimWarning')
      Sentry.capture_exception(e)
      nil
    end

    def self.nominatim_lookup(query, city, state, postalcode, country)
      return if Rails.cache.read(['Nominatim', 'API PAUSE'])

      address = [query, city, state, postalcode, country].compact.join(',')
      n = Geocoder.search(address)

      # Limit calls to 1 per second (we are defaulting to using Nominatim, and this is their policy)
      @rate_limit ||= Time.new(0)
      sleep 1 if (Time.current - @rate_limit) < 1
      result = n.first
      @rate_limit = Time.current

      return result
    rescue Faraday::ConnectionFailed
      # we've probably been banned, let the API cool off
      Rails.cache.write(['Nominatim', 'API PAUSE'], true, expires_in: 1.hours)
    rescue StandardError => e
      # The API returns various errors which we don't want to prevent continuing with other attempts.
      # Just send it along to sentry and take a quick break
      Sentry.capture_exception(e)
      sleep 1
    end
    nil
  end
end
