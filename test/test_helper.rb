ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # NO FIXTURES please
  # use db/seed scripts or build content in each test
  # fixtures :all

  # Add more helper methods to be used by all tests here...
end
