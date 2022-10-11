# Rails.logger.debug "Running initializer in #{__FILE__}"

Nominatim.configure do |config|
  # config.email = 'your-email-address@example.com'
  config.endpoint = 'https://nominatim.openstreetmap.org/search'
end
