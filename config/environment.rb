# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
begin
  # Rescue when we don't yet have a DB, maybe related to LSA, or just delay, but this
  # only occurs on deploy and console boot on deployed instances, and appears to have
  # no negative impacts
  Rails.application.initialize!
rescue StandardError, ActiveRecord::ConnectionNotEstablished => e
  Sentry.capture_exception_with_info(
    StandardError.new('App failed to boot, you can probably ignore this. Caused by ActiveRecord::ConnectionNotEstablished'),
    'App failed to boot',
    { backtrace: e.backtrace.to_s }
  )
end
