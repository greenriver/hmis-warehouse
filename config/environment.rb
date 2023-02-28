# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
begin
  Rails.application.initialize!
# Rescue when we don't yet have a DB, maybe related to LSA, or just delay, but this
# only occurs on deploy and console boot on deployed instances, and appears to have
# no negative impacts
rescue ActiveRecord::ConnectionNotEstablished
end
