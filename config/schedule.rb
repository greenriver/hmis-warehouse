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

# All installs get these
daily_schedule = ENV['DAILY_SCHEDULE'] || '3:10 am'
every 1.day, at: daily_schedule do
  # Long-running
  rake "grda_warehouse:daily"
end
shifted_time = Time.parse(daily_schedule) - 2.hours
every 1.day, at: shifted_time.strftime('%I:%M %P') do
  # Defers to delayed jobs
  rake "grda_warehouse:process_recurring_hmis_exports"
end
shifted_time = Time.parse(daily_schedule) - 5.minutes
every 1.day, at: shifted_time.strftime('%I:%M %P') do
  # Fast and low RAM
  rake "grda_warehouse:secure_files:clean_expired"
end

# refresh this every six hours, during the day
every 1.day, at: ['7:15 am', '1:15 pm', '7:15 pm']  do
  # Defers to delayed jobs
  rake "grda_warehouse:warm_cohort_cache"
end

every 1.hour do
  # Fast and low RAM
  rake "grda_warehouse:hourly"
end

every 5.minutes do
  # Long-running, but infrequently so
  rake 'reporting:frequent'
end

if ENV['ECS'] == 'true'
  every 2.minutes do
    rake 'jobs:arbitrate_workoff'
  end
end

every 4.hours do
  # Defers to delayed jobs
  rake "grda_warehouse:save_service_history_snapshots"
end

if ENV['LSA_DB_HOST'].to_s != ''
  every 3.hours do
    rake 'reporting:lsa_shut_down'
  end
end

every 1.day, at: '4:02 am' do
  # FIXME May need to be back-grounded?
  rake "messages:daily"
end

# These only happen in some scenarios, now DB based
every 1.day, at: '6:04 am' do
  # Defers to delayed jobs
  rake "eto:import:demographics_and_touch_points"
end


import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
every 1.day, at: import_schedule do
  # Defers to delayed jobs
  rake "grda_warehouse:import_data_sources_s3"
end
shifted_time = Time.parse(import_schedule) - 4.hours
every 1.day, at: shifted_time.strftime('%I:%M %P') do
  rake "grda_warehouse:ftps_s3_sync"
end


if ENV['HEALTH_SFTP_HOST'].to_s != '' && ENV['HEALTH_SFTP_HOST'] != 'hostname' && ENV['RAILS_ENV'] == 'production'
  every 1.day, at: '11:03 am' do
    # Defers to delayed jobs
    rake "health:daily"
  end
  every 1.day, at: '6:01 am' do
    rake "health:enrollments_and_eligibility"
  end
end

if ENV['GLACIER_NEEDS_BACKUP']=='true'
  import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
  database_backup_time = Time.parse(import_schedule) - 3.hours

  every :month, at: database_backup_time do
    rake "glacier:backup:database"
  end

  if ENV['GLACIER_FILESYSTEM_BACKUP'] == 'true'
    # Files are for the logs, these end up in CloudWatch for ECS deployments
    every :month, at: database_backup_time-1.hours do
      rake "glacier:backup:files"
    end
  end
end
