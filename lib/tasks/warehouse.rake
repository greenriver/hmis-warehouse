# frozen_string_literal: true

task spec: ['warehouse:db:test:prepare']

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :warehouse do
  # DB related, provides warehouse:db:migrate etc.
  namespace :db do |_ns|
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
        # Work-around for pg_dump 17.6, which adds \restrict and \unrestrict to the structure file
        # Fixed in a future version of active record: https://github.com/rails/rails/pull/55531/files
        Rake::Task['db:schema:dump'].enhance do
          schema_file = Rails.root.join('db', 'warehouse_structure.sql')
          schema = File.read(schema_file)
          schema.gsub!(/^\\restrict/, '-- \restrict')
          schema.gsub!(/^\\unrestrict/, '-- \unrestrict')
          File.write(schema_file, schema)
        end
      end

      desc 'Conditionally load the database schema'
      task :conditional_load, [] => [:environment] do |_t, _args|
        GrdaWarehouseBase.load_db_if_empty do
          Rake::Task['db:schema:load:warehouse'].invoke
        end
      end
    end

    namespace :structure do
      task :load do
        Rake::Task['db:structure:load'].invoke
      end

      task :dump do
        # Work-around for pg_dump 17.6, which adds \restrict and \unrestrict to the structure file
        # Fixed in a future version of active record: https://github.com/rails/rails/pull/55531/files
        Rake::Task['db:structure:dump'].enhance do
          schema_file = Rails.root.join('db', 'warehouse_structure.sql')
          schema = File.read(schema_file)
          schema.gsub!(/^\\restrict/, '-- \restrict')
          schema.gsub!(/^\\unrestrict/, '-- \unrestrict')
          File.write(schema_file, schema)
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
