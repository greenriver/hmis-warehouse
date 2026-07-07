###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: Rails.root.join("lib", "GeoLite2-City", "GeoLite2-City.mmdb")
  },
  http_headers: {
    "User-Agent" => "info@greenriver.com"
  },
  timeout: 10,
)
