require 'dotenv'
Dotenv.load('.env', '.env.local')
# Use this file to easily define all of your cron jobs.
#
# It's helpful, but not entirely necessary to understand cron before proceeding.
# http://en.wikipedia.org/wiki/Cron

# Example:
#
# set :output, "/path/to/my/cron_log.log"
#
# every 2.hours do
#   command "/usr/bin/some_great_command"
#   runner "MyModel.some_method"
#   rake "some:great:rake:task"
# end
#
# every 4.days do
#   runner "AnotherModel.prune_old_records"
# end

# Learn more: http://github.com/javan/whenever
if environment == 'production'

  # All installs get these
  daily_schedule = ENV['DAILY_SCHEDULE'] || '3:10 am'
  every 1.day, at: daily_schedule do
    rake "grda_warehouse:daily"
    rake "grda_warehouse:process_recurring_hmis_exports"
  end

  # refresh this every six hours, during the day
  every 1.day, at: ['7:15 am', '1:15 pm', '7:15 pm']  do
    rake "grda_warehouse:warm_cohort_cache"
  end

  every 1.hour do
    rake "jobs:check_queue"
  end

  every 4.hours do
    rake "grda_warehouse:save_service_history_snapshots"
  end

  every 1.day, at: '4:00 am' do
    rake "messages:daily"
  end

  # These only happen in some scenarios
  if ENV['ETO_API_SITE1'] != 'unknown'
    every 1.day, at: '4:00 pm' do
      rake "eto:import:update_ids_and_demographics"
    end
  end

  if ENV['BOSTON_ETO_S3_REGION'] != nil && ENV['BOSTON_ETO_S3_REGION'] != ''
    import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
    every 1.day, at: import_schedule do
      rake "grda_warehouse:import_data_sources_s3[hmis_611]"
    end
  end

  if ENV['HEALTH_SFTP_HOST'] != 'hostname'
    every 1.day, at: '10:00 am' do
      rake "health:daily"
    end
  end

  if ENV['GLACIER_NEEDS_BACKUP']=='true'
    import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
    database_backup_time = Time.parse(import_schedule) - 3.hours

    every :month, at: database_backup_time do
      rake "glacier:backup:database"
    end

    every :month, at: database_backup_time-1.hour do
      rake "glacier:backup:files"
    end
  end
end
