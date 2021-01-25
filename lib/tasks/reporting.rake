task spec: ["db:test:prepare:reporting"]

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
  end

  namespace :db do |ns|
    namespace :schema do
      desc "Conditionally load the database schema"
      task :conditional_load, [] => [:environment] do |t, args|
        if ReportingBase.connection.tables.length == 0
          Rake::Task['db:schema:load:reporting'].invoke
        else
          puts "Refusing to load the reporting database schema since there are tables present. This is not an error."
        end
      end
    end

    namespace :structure do
      desc "Conditionally load the database structure"
      task :conditional_load, [] => [:environment] do |t, args|
        if ReportingBase.connection.tables.length == 0
          Rake::Task['db:structure:load:reporting'].invoke
        else
          puts "Refusing to load the reporting database structure since there are tables present. This is not an error."
        end
      end
    end
  end
end
