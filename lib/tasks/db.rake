# frozen_string_literal: true

namespace :db do
  namespace :schema do
    desc 'Conditionally load the database schema'
    task :conditional_load, [] => [:environment] do |_t, _args|
      ApplicationRecord.load_db_if_empty do
        Rake::Task['db:schema:load:primary'].invoke
      end
    end
  end

  namespace :structure do
    namespace :conditional_load do
      desc 'Conditionally load the database structure (primary)'
      task :primary, [] => [:environment] do |_t, _args|
        ApplicationRecord.load_db_if_empty do
          ApplicationRecord.connection.execute(File.read('db/structure.sql'))
        end
      end

      desc 'Conditionally load the database structure (warehouse)'
      task :warehouse, [] => [:environment] do |_t, _args|
        GrdaWarehouseBase.load_db_if_empty do
          GrdaWarehouseBase.connection.execute(File.read('db/warehouse_structure.sql'))
        end
      end

      desc 'Conditionally load the database structure (health)'
      task :health, [] => [:environment] do |_t, _args|
        HealthBase.load_db_if_empty do
          HealthBase.connection.execute(File.read('db/health_structure.sql'))
        end
      end

      desc 'Conditionally load the database structure (reporting)'
      task :reporting, [] => [:environment] do |_t, _args|
        ReportingBase.load_db_if_empty do
          ReportingBase.connection.execute(File.read('db/reporting_structure.sql'))
        end
      end
    end
  end

  desc 'Setup all test DB'
  task :setup_test do
    raise 'MUST be run in the test environment' unless Rails.env.test?

    [
      'DATABASE_APP_DB_TEST',
      'WAREHOUSE_DATABASE_DB_TEST',
      'HEALTH_DATABASE_DB_TEST',
      'REPORTING_DATABASE_DB_TEST',
    ].each do |var|
      db_name = ENV.fetch(var)
      raise "Unset test DB variable #{var}" unless db_name.present?
    end
    system 'RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load'
  end
end
