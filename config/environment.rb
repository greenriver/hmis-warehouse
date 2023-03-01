# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
begin
  # Rescue when we don't yet have a DB, maybe related to LSA, or just delay, but this
  # only occurs on deploy and console boot on deployed instances, and appears to have
  # no negative impacts
  Rails.application.initialize!
rescue ActiveRecord::ConnectionNotEstablished => e
  Sentry.capture_exception_with_info(
    ActiveRecord::ConnectionNotEstablished.new('App failed to boot, you can probably ignore this'),
    'App failed to boot',
    { backtrace: e.backtrace.to_s }
  )
end
