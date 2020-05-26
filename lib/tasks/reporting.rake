task spec: ["reporting:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :reporting do

  desc "Run Project Data Quality Reports"
  task run_project_data_quality_reports: [:environment] do
    GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.delay.process!
  end

  desc "Run Ad-Hoc Upload processing"
  task run_ad_hoc_processing: [:environment] do
    GrdaWarehouse::AdHocBatch.delay.process!
  end

  # DB related, provides reporting:db:migrate etc.
  namespace :db do |ns|

    task :drop do
      Rake::Task["db:drop"].invoke
    end

    task :create do
      Rake::Task["db:create"].invoke
    end

    task :setup do
      Rake::Task["db:setup"].invoke
    end

    task :migrate do
      Rake::Task["db:migrate"].invoke
    end

    namespace :migrate do
      task :redo do
        Rake::Task["db:migrate:redo"].invoke
      end
      task :up do
        Rake::Task["db:migrate:up"].invoke
      end
      task :down do
        Rake::Task["db:migrate:down"].invoke
      end
    end

    task :rollback do
      Rake::Task["db:rollback"].invoke
    end

    task :seed do
      Rake::Task["db:seed"].invoke
    end

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

      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if ReportingBase.connection.tables.length == 0
          Rake::Task['reporting:db:schema:load'].invoke
        else
          puts "Refusing to load the reporting database schema since there are tables present. This is not an error."
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
    end

    namespace :test do
      task :prepare do
        Rake::Task["db:test:prepare"].invoke
      end
    end

    # append and prepend proper tasks to all the tasks defined here above
    ns.tasks.each do |task|
      task.enhance ["reporting:set_custom_config"] do
        Rake::Task["reporting:revert_to_original_config"].invoke
      end
    end
  end

  task set_custom_config: [:environment] do
    ReportingBase.setup_config
  end

  task revert_to_original_config: [:environment] do
    ApplicationRecord.setup_config
  end
end
