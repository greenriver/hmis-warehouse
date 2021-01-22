task spec: ["warehouse:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :warehouse do

  # DB related, provides warehouse:db:migrate etc.
  namespace :db do |ns|
    
    task :version do
      Rake::Task["db:version"].invoke
    end

    namespace :schema do
      task :load do
        Rake::Task["db:schema:load"].invoke
      end

      task :dump do
        Rake::Task["db:schema:dump"].invoke
      end

      # keep this but with alternations
      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if GrdaWarehouseBase.connection.tables.length < 2
          Rake::Task['warehouse:db:schema:load'].invoke
        else
          puts "Refusing to load the warehouse database schema since there are tables present. This is not an error."
        end
      end
    end

    namespace :structure do
      task :load do
        Rake::Task["db:structure:load"].invoke
      end

      task :dump do
        Rake::Task["db:structure:dump"].invoke
      end

      # keep this but with alternations
      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if GrdaWarehouseBase.connection.tables.length == 0
          GrdaWarehouseBase.connection.execute(File.read('db/warehouse/structure.sql'))
        else
          puts "Refusing to load the warehouse database structure since there are tables present. This is not an error."
        end
      end
    end

    namespace :test do
      task :prepare do
        Rake::Task["db:test:prepare"].invoke
      end
    end

    # append and prepend proper tasks to all the tasks defined here above
    ns.tasks.each do |task|
      task.enhance ["warehouse:set_custom_config"] do
        Rake::Task["warehouse:revert_to_original_config"].invoke
      end
    end
  end

  task set_custom_config: [:environment] do
    GrdaWarehouseBase.setup_config
  end

  task revert_to_original_config: [:environment] do
    ApplicationRecord.setup_config
  end
end
