Rails.logger.debug "Running initializer in #{__FILE__}"

Rails.configuration.to_prepare do
  AuthTrail::GeocodeJob.queue_as :short_running
end