Rails.logger.debug "Running initializer in #{__FILE__}"

Rails.configuration.to_prepare do
  AuthTrail.geocode = true
  AuthTrail::GeocodeJob.queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
  AuthTrail.transform_method = lambda do |data, request|
    data[:user] ||= User.find_by(email: data[:identity])
  end
end
