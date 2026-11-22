###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

geocoder_options = {
  ip_lookup: :geoip2,
  geoip2: {
    file: Rails.root.join('lib', 'GeoLite2-City', 'GeoLite2-City.mmdb'),
  },
  http_headers: {
    'User-Agent' => 'info@greenriver.com',
  },
  timeout: 10,
}

# NOMINATIM_HOST is a base URL such as http://nominatim.example:8080.
# Geocoder builds "#{scheme}://#{host}/search", so host carries the port and any path prefix.
# Geocoder logs network errors and returns no results unless always_raise lists them;
# raising lets GrdaWarehouse::Place.nominatim_lookup pause lookups while the self-hosted server is down.
if ENV['NOMINATIM_HOST'].present?
  nominatim_uri = URI.parse(ENV['NOMINATIM_HOST'])
  raise ArgumentError, "NOMINATIM_HOST must be an http:// or https:// URL, got #{ENV['NOMINATIM_HOST'].inspect}" unless nominatim_uri.is_a?(URI::HTTP) && nominatim_uri.host.present?

  geocoder_options[:nominatim] = {
    host: "#{nominatim_uri.host}:#{nominatim_uri.port}#{nominatim_uri.path.chomp('/')}",
    use_https: nominatim_uri.scheme == 'https',
    timeout: 30,
    always_raise: [SocketError, Errno::ECONNREFUSED, Geocoder::LookupTimeout, Geocoder::NetworkError],
  }
end

Geocoder.configure(geocoder_options)
