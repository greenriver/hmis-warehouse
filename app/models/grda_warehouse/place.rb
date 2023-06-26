###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse
  class Place < GrdaWarehouseBase
    include NotifierConfig

    NominatimApiPaused = Class.new(StandardError)

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
        place = @places[key] = begin
          nr = nominatim_lookup(query, city, state, postalcode, country)
          if nr.present?
            lat_lon = { lat: nr.lat, lon: nr.lon, bounds: nr.boundingbox }.with_indifferent_access
            Place.create!(location: key, lat_lon: lat_lon) if nr.present?
          end
        end
      end
      place
    rescue NominatimApiPaused
      return nil
    rescue StandardError
      setup_notifier('NominatimWarning')
      @notifier.ping('Error contacting the OSM Nominatim API.') if @send_notifications
      nil
    end

    def self.nominatim_lookup(query, city, state, postalcode, country)
      raise NominatimApiPaused if Rails.cache.read(['Nominatim', 'API PAUSE'])

      n = Nominatim.search(query)
      n = n.city(city) if city.present?
      n = n.state(state) if state.present?
      n = n.postalcode(postalcode) if postalcode.present?
      n = n.country(country) if country.present?

      # Limit Nominatim calls to 1 per second
      @rate_limit ||= Time.new(0)
      sleep 1 if (Time.current - @rate_limit) < 1
      result = n.first
      @rate_limit = Time.current

      result
    rescue Faraday::ConnectionFailed
      # we've probably been banned, let the API cool off
      Rails.cache.write(['Nominatim', 'API PAUSE'], true, expires_in: 1.hours)
      raise NominatimApiPaused
    end
  end
end
