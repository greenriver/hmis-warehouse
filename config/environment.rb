# Load the Rails application.
require_relative 'application'

begin
  Rails.application.initialize!
rescue ActiveRecord::ConnectionNotEstablished => e
  # Rescue when we don't yet have a DB, maybe related to LSA, or just delay, but this
  # only occurs on deploy and console boot on deployed instances, and appears to have
  # no negative impacts
  Rails.logger.warn("Ignorable error occured on bootup: #{e.message}")
end
