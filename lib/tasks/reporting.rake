task spec: ["reporting:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :reporting do

  desc "Run Project Data Quality Reports"
  task run_project_data_quality_reports: [:environment] do
    report_class = GrdaWarehouse::WarehouseReports::Project::DataQuality::Base
    advisory_lock_key = "project_data_quality_reports"
    if report_class.advisory_lock_exists?(advisory_lock_key)
      Rails.logger.info 'Exiting, project data quality reports already running'
      exit
    end
    include NotifierConfig
    setup_notifier('Project Data Quality Report Runner')
    GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.with_advisory_lock(advisory_lock_key) do
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.where(completed_at: nil).each do |r|
        begin
          r.run!
        rescue Exception => e
          Rails.logger.error e.message
          ExceptionNotifier.notify_exception(e) if @send_notifications
        end
      end
    end
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

  task :set_custom_config do
    # save current vars
    @original_config = {
      env_schema: ENV['SCHEMA'],
      config: Rails.application.config.dup
    }

    # set config variables for custom database
    ENV['SCHEMA'] = "db/reporting/schema.rb"
    Rails.application.config.paths['db'] = ["db/reporting"]
    Rails.application.config.paths['db/migrate'] = ["db/reporting/migrate"]
    Rails.application.config.paths['db/seeds'] = ["db/reporting/seeds.rb"]
    Rails.application.config.paths['config/database'] = ["config/database_reporting.yml"]
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]
  end

  task :revert_to_original_config do
    # reset config variables to original values
    db_config = Rails.application.config.paths['config/database'].to_a.first
    ActiveRecord::Base.establish_connection YAML.load(ERB.new(File.read(db_config)).result)[Rails.env]

    ENV['SCHEMA'] = @original_config[:env_schema]
    Rails.application.config = @original_config[:config]
  end
end
