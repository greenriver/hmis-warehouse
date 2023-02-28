# Load the Rails application.
require_relative 'application'

# Initialize the Rails application.
begin
  Rails.application.initialize!
rescue ActiveRecord::ConnectionNotEstablished
end
