# frozen_string_literal: true

# Start Monkey Patch for pg_dump 17.6
# Helper method to fix pg_dump 17.6 \restrict and \unrestrict commands
# Dynamically determines which structure file to fix based on the current database connection
def fix_pg_dump_restrict_commands
  return unless Rails.env.development? || Rails.env.test?

  [
    'structure.sql',
    'warehouse_structure.sql',
    'health_structure.sql',
    'reporting_structure.sql',
    'cas_structure.sql',
  ].each do |file_name|
    structure_file = Rails.root.join('db', file_name)
    schema = File.read(structure_file)
    next unless schema.match?(/^\\restrict|^\\unrestrict/)

    schema.gsub!(/^\\restrict/, '-- \restrict')
    schema.gsub!(/^\\unrestrict/, '-- \unrestrict')
    File.write(structure_file, schema)
  end
end

Rake::Task['db:schema:dump'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:migrate:primary'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:schema:dump:primary'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:migrate:warehouse'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:schema:dump:warehouse'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:migrate:health'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:schema:dump:health'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:migrate:reporting'].enhance do
  fix_pg_dump_restrict_commands
end

Rake::Task['db:schema:dump:reporting'].enhance do
  fix_pg_dump_restrict_commands
end
# End Monkey Patch for pg_dump 17.6

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
