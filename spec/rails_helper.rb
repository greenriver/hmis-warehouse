# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV['RAILS_ENV'] = 'test'
require File.expand_path('../config/environment', __dir__)
# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?
require 'spec_helper'
require 'rspec/rails'
require 'deprecation_helper'
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
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migration and applies them before tests are run.
# If you are not using ActiveRecord, you can remove this line.
# ActiveRecord::Migration.maintain_test_schema!
# ActiveRecord::Migration.maintain_test_schema!
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

  # RSpec Rails can automatically mix in different behaviors to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behavior by removing the line below, and instead
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
  config.include AccessControlSetup

  require_relative 'support/s3_utils'
  config.include S3Utils

  config.before(:suite) do
    # disable paper trail for test performance
    PaperTrail.enabled = false

    # disable rack attack unless we are testing it explicitly
    Rack::Attack.enabled = false

    example_file_paths = RSpec.world.filtered_examples.values.flatten.map { |e| e.metadata[:file_path] }.uniq
    # load fixpoints if we're running tests that may need them
    if example_file_paths.grep(%r{/drivers/(hud_path_report|hud_spm_report|hud_data_quality_report)/}).any? # rubocop:disable Style/RegexpLiteral
      Dir.glob('{drivers,spec}/**/fixpoints/*.yml').each do |filename|
        FileUtils.rm(filename)
      end
      Dir.glob('{drivers,spec}/**/fixpoints/*.sql').each do |filename|
        # The 2024 test kit is HUGE, so we'll use the preprocessed version
        # This means when the test kit changes, we need to update both the CSVs and the SQL fixpoint
        # To rebuild, push a commit that contains `[gh:rebuild_fixpoints]` in the commit message.
        next if filename.include?('drivers/datalab_testkit/spec/fixpoints')

        FileUtils.rm(filename)
      end
      GrdaWarehouse::WarehouseReports::ReportDefinition.maintain_report_definitions
    end

    # load hmis forms if we're testing the driver
    if example_file_paths.grep(%r{/drivers/hmis/}).any? # rubocop:disable Style/RegexpLiteral
      ::HmisUtil::JsonForms.seed_all if ENV['ENABLE_HMIS_API'] == 'true'
    end

    # I'm not sure that we need these on every test run
    # GrdaWarehouse::Utility.clear!
    # Delayed::Job.delete_all
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

VCR.configure do |config|
  config.ignore_hosts('127.0.0.1', 'localhost', 'minio', 's3.dev.test')
end

def cleanup_test_environment
  GrdaWarehouse::Utility.clear!
  User.delete_all
  FactoryBot.reload
end

def default_excluded_tables
  ['versions', 'spatial_ref_sys', 'homeless_summary_report_clients', 'homeless_summary_report_results', 'hmis_csv_importer_logs', 'hap_report_clients', 'simple_report_cells', 'simple_report_universe_members', 'whitelisted_projects_for_clients', 'hmis_csv_import_validations', 'uploads', 'hmis_csv_loader_logs', 'import_logs', 'delayed_jobs', 'translations', 'schema_migrations'] +
  HmisCsvImporter::Loader::Loader.loadable_files.values.map(&:table_name) +
  HmisCsvImporter::Importer::Importer.importable_files.values.map(&:table_name)
end
