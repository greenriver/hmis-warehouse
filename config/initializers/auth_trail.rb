# frozen_string_literal: true

# Rails.logger.debug "Running initializer in #{__FILE__}"

Rails.configuration.to_prepare do
  AuthTrail.geocode = true
  AuthTrail::GeocodeJob.queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)
  AuthTrail.transform_method = lambda do |data, _request|
    data[:user] ||= case data[:scope].to_s
    when 'hmis_user'
      Hmis::User.find_by(email: data[:identity])
    else
      User.find_by(email: data[:identity])
    end
  end
end
