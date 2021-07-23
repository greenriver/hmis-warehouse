# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
# require 'simplecov'
# require 'simplecov-console'
# SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new(
#   [
#     SimpleCov::Formatter::HTMLFormatter,
#     SimpleCov::Formatter::Console,
#   ],
# )
# SimpleCov.start 'rails'
# Disabling SimpleCov, it is too noisy
# SimpleCov.start
# SimpleCov.add_filter '/test/'

# Add additional requires below this line. Rails is not loaded until this point!

# Requires supporting ruby files with custom matchers and macros
# Lazy way if we get many of these Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
require Rails.root.join('spec/support/hmis_csv_fixtures')

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!
ActiveRecord::Migration.maintain_test_schema!
# These will eventually be replaced with similar when we move to Rails 6
# system 'RAILS_ENV=test bin/rake warehouse:db:migrate'
# system 'RAILS_ENV=test bin/rake health:db:migrate'
# system 'RAILS_ENV=test bin/rake reporting:db:migrate'

RSpec.configure do |config|
  ENV['NO_LSA_RDS'] = 'true'
  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, :type => :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://relishapp.com/rspec/rspec-rails/docs
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")

  config.include Devise::Test::ControllerHelpers, type: :controller
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include FactoryBot::Syntax::Methods
  config.include HmisCsvFixtures

  config.include FixpointTestHelpers

  config.before(:suite) do
    GrdaWarehouse::Utility.clear!
    Delayed::Job.delete_all
    GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    AccessGroup.maintain_system_groups
  end
end

# Drivers
Dir[Rails.root.join('drivers/*/spec/support/*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  FactoryBot.definition_file_paths += Dir['drivers/*/spec/factories']
  FactoryBot.reload

  Dir[Rails.root.join('drivers/*/spec')].each { |x| config.project_source_dirs << x }
  Dir[Rails.root.join('drivers/*/lib')].each { |x| config.project_source_dirs << x }
  Dir[Rails.root.join('drivers/*/app')].each { |x| config.project_source_dirs << x }
end
