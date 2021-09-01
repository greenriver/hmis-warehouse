Rails.logger.debug "Running initializer in #{__FILE__}"

Rails.configuration.to_prepare do
  AuthTrail::GeocodeJob.queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
end
