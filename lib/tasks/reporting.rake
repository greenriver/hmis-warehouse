task spec: ["reporting:db:test:prepare"]

require 'dotenv'
Dotenv.load('.env', '.env.local')

namespace :reporting do

  desc "Run Project Data Quality Reports"
  task run_project_data_quality_reports: [:environment] do
    GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.process!
  end

  desc "Run Ad-Hoc Upload processing"
  task run_ad_hoc_processing: [:environment] do
    GrdaWarehouse::AdHocBatch.process!
  end

  # If there are no incomplete LSA reports that have changed in the past day,
  # shut down the LSA server, we'll spool it up on-demand
  desc 'Shutdown unused LSA Servers'
  task lsa_shut_down: [:environment] do
    # Note the current state
    load 'lib/rds_sql_server/rds.rb'
    begin
      state = Rds.new.current_state
    rescue Aws::RDS::Errors::DBInstanceNotFound
      state = 'unknown'
    end
    GrdaWarehouse::LsaRdsStateLog.create(state: state)

    lsa_report_ids = Report.where(Report.arel_table[:type].matches('%::Lsa::%')).pluck(:id)
    exit if ReportResult.incomplete.updated_today.where(report_id: lsa_report_ids).exists?

    Rds.new.stop!
  end

  desc 'Frequent reporting tasks'
  task frequent: [:environment] do
    begin
      GrdaWarehouse::WarehouseReports::Project::DataQuality::Base.process!
    rescue StandardError => e
      puts e.message
    end
    begin
      GrdaWarehouse::AdHocBatch.process!
    rescue StandardError => e
      puts e.message
    end

    ApplicationNotifier.flush_queues
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
        if ReportingBase.connection.table_exists?(:schema_migrations)
          puts "Refusing to load the reporting database schema since there are tables present. This is not an error."
        else
          Rake::Task['db:schema:load:reporting'].invoke
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

      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if ReportingBase.connection.table_exists?(:schema_migrations)
          puts "Refusing to load the reporting database structure since there are tables present. This is not an error."
        else
          ReportingBase.connection.execute(File.read('db/reporting/structure.sql'))
        end
      end
    end

    namespace :test do
      task :prepare do
        Rake::Task["db:test:prepare"].invoke
      end
    end
  end
end
