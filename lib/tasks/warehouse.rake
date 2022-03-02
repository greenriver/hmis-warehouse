task spec: ['warehouse:db:test:prepare']

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :warehouse do
  # DB related, provides warehouse:db:migrate etc.
  namespace :db do |ns|
    task :drop do
      Rake::Task['db:drop'].invoke
    end

    task :create do
      Rake::Task['db:create'].invoke
    end

    task :setup do
      Rake::Task['db:setup'].invoke
    end

    task :migrate do
      Rake::Task['db:migrate'].invoke
    end

    namespace :migrate do
      task :redo do
        Rake::Task['db:migrate:redo'].invoke
      end
      task :up do
        Rake::Task['db:migrate:up'].invoke
      end
      task :down do
        Rake::Task['db:migrate:down'].invoke
      end
    end

    task :rollback do
      Rake::Task['db:rollback'].invoke
    end

    task :seed do
      Rake::Task['db:seed'].invoke
    end

    task :version do
      Rake::Task['db:version'].invoke
    end

    namespace :schema do
      task :load do
        Rake::Task['db:schema:load'].invoke
      end

      task :dump do
        Rake::Task['db:schema:dump'].invoke
      end

      desc 'Conditionally load the database schema'
      task :conditional_load, [] => [:environment] do |_t, _args|
        if GrdaWarehouseBase.connection.table_exists?(:schema_migrations)
          puts 'Refusing to load the warehouse database schema since there are tables present. This is not an error.'
        else
          Rake::Task['db:schema:load:warehouse'].invoke
        end
      end
    end

    namespace :structure do
      task :load do
        Rake::Task['db:structure:load'].invoke
      end

      task :dump do
        Rake::Task['db:structure:dump'].invoke
      end

      desc 'Conditionally load the database structure'
      task :conditional_load, [] => [:environment] do |_t, _args|
        if GrdaWarehouseBase.connection.table_exists?(:schema_migrations)
          puts 'Refusing to load the warehouse database structure since there are tables present. This is not an error.'
        else
          GrdaWarehouseBase.connection.execute(File.read('db/warehouse_structure.sql'))
        end
      end
    end

    namespace :test do
      task :prepare do
        Rake::Task['db:test:prepare'].invoke
      end
    end
  end
end
