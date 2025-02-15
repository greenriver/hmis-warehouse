ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
require 'logger' # required before bootsnap setup or ActiveSupport::LoggerThreadSafeLevel::Logger can't be found
require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
