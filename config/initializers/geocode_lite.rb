Rails.logger.debug "Running initializer in #{__FILE__}"

Geocoder.configure(
  ip_lookup: :geoip2,
  geoip2: {
    file: Rails.root.join("lib", "GeoLite2-City", "GeoLite2-City.mmdb")
  }
)
