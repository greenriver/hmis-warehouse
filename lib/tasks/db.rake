namespace :db do
  namespace :migrate do
    desc "Call the db:migrate subvariant for all the different databases"
    task :all do
      system 'bin/rake db:migrate'
      system 'bin/rake warehouse:db:migrate'
      system 'bin/rake health:db:migrate'
      system 'bin/rake reporting:db:migrate'
    end
  end

  desc "Setup all test DB"
  task :setup_test do
    raise 'MUST be run in the test environment' unless Rails.env.test?
    [
      'APP_DATABASE_DB_TEST',
      'WAREHOUSE_DATABASE_DB_TEST',
      'HEALTH_DATABASE_DB_TEST',
      'REPORTING_DATABASE_DB_TEST',
    ].each do |var|
      db_name = ENV.fetch(var)
      raise "Unset test DB variable #{var}" unless db_name.present?
    end
    system 'RAILS_ENV=test bundle exec rake db:drop db:create db:schema:load'
    system 'RAILS_ENV=test bundle exec rake warehouse:db:drop warehouse:db:create warehouse:db:schema:load'
    system 'RAILS_ENV=test bundle exec rake health:db:drop health:db:create health:db:schema:load'
    system 'RAILS_ENV=test bundle exec rake reporting:db:drop reporting:db:create reporting:db:schema:load'
  end
end
