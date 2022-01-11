namespace :db do
  namespace :schema do
    desc "Conditionally load the database schema"
    task :conditional_load, [] => [:environment] do |t, args|
      if ApplicationRecord.connection.table_exists?(:schema_migrations)
        puts "Refusing to load the database schema since there are tables present. This is not an error."
      else
        Rake::Task['db:schema:load:primary'].invoke
      end
    end
  end

  namespace :structure do
    desc "Conditionally load the database structure"
    task :conditional_load, [] => [:environment] do |t, args|
      if ApplicationRecord.connection.table_exists?(:schema_migrations)
        puts "Refusing to load the database structure since there are tables present. This is not an error."
      else
        Rake::Task['db:structure:load'].invoke
      end
    end
  end

  desc "Setup all test DB"
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
