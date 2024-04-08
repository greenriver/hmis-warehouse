# Load the Rails application.
require_relative 'application'

begin
  Rails.application.initialize!
rescue StandardError, ActiveRecord::ConnectionNotEstablished => e
  # Rescue when we don't yet have a DB, maybe related to LSA, or just delay, but this
  # only occurs on deploy and console boot on deployed instances, and appears to have
  # no negative impacts
  Sentry.capture_exception(e)
  Rails.logger.fatal("Application failed to start: #{e.message}")
end
