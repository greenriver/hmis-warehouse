require 'dotenv'
require 'active_support/core_ext/object/blank'
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

# setup
daily_schedule = ENV['DAILY_SCHEDULE'] || '3:10 am'
import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
glacier_import_schedule = ENV['IMPORT_SCHEDULE'] || '5:30 pm'
export_schedule = if ENV['DAILY_EXPORT_SCHEDULE'].nil? || ENV['DAILY_EXPORT_SCHEDULE'].empty? then (Time.parse(daily_schedule) - 2.hours).strftime('%I:%M %P') else ENV['DAILY_EXPORT_SCHEDULE'] end
file_cleaning_schedule = (Time.parse(daily_schedule) - 5.minutes).strftime('%I:%M %P')
import_prefetch_schedule = (Time.parse(import_schedule) - 4.hours).strftime('%I:%M %P')
census_schedule = (Time.parse(import_schedule) - 5.hours).strftime('%I:%M %P')
database_backup_time = Time.parse(import_schedule) - 3.hours

health_trigger = ENV['HEALTH_SFTP_HOST'].to_s != '' && ENV['HEALTH_SFTP_HOST'] != 'hostname' && ENV['RAILS_ENV'] == 'production'
backup_glacier_trigger = ENV['GLACIER_NEEDS_BACKUP'] == 'true'
glacier_files_backup_trigger = backup_glacier_trigger && ENV['GLACIER_FILESYSTEM_BACKUP'] == 'true'
tasks = [
  {
    task: 'grda_warehouse:daily',
    frequency: 1.day,
    at: daily_schedule,
    interruptable: false,
  },
  {
    task: 'grda_warehouse:process_recurring_hmis_exports',
    frequency: 1.day,
    at: export_schedule,
    interruptable: false,
  },
  {
    task: 'grda_warehouse:secure_files:clean_expired',
    frequency: 1.day,
    at: file_cleaning_schedule,
    interruptable: true,
  },
  {
    task: 'grda_warehouse:warm_cohort_cache',
    frequency: 1.day,
    at: ['7:15 am', '1:15 pm', '7:15 pm'],
    interruptable: true,
  },
  {
    task: 'grda_warehouse:hourly',
    frequency: 1.hour,
    interruptable: true,
  },
  {
    task: 'reporting:frequent',
    frequency: 5.minutes,
    interruptable: false,
  },
  {
    task: 'jobs:arbitrate_workoff',
    frequency: 2.minutes,
    trigger: ENV['ECS'] == 'true',
    interruptable: true,
  },
  {
    task: 'grda_warehouse:save_service_history_snapshots',
    frequency: 4.hours,
    interruptable: true,
  },
  {
    task: 'reporting:lsa_shut_down',
    frequency: 3.hours,
    trigger: ENV['LSA_DB_HOST'].to_s != '',
    interruptable: true,
  },
  {
    task: 'messages:daily',
    frequency: 1.day,
    at: '4:02 am',
    interruptable: false,
  },
  {
    task: 'eto:import:demographics_and_touch_points',
    frequency: 1.day,
    at: '6:04 am',
    interruptable: false,
  },
  {
    task: 'grda_warehouse:import_data_sources_s3',
    frequency: 1.day,
    at: import_schedule,
    interruptable: false,
  },
  {
    task: 'grda_warehouse:ftps_s3_sync',
    frequency: 1.day,
    at: import_prefetch_schedule,
    interruptable: false,
  },
  {
    task: 'us_census_api:all',
    frequency: 1.month,
    at: census_schedule,
    interruptable: false,
  },
  {
    task: 'health:daily',
    frequency: 1.day,
    at: '11:03 am',
    trigger: health_trigger,
    interruptable: false,
  },
  {
    task: 'health:enrollments_and_eligibility',
    frequency: 1.day,
    at: '6:01 am',
    trigger: health_trigger,
    interruptable: false,
  },
  {
    task: 'health:hourly',
    frequency: 1.hour,
    trigger: health_trigger,
    interruptable: true,
  },
  {
    task: 'glacier:backup:database',
    frequency: 1.month,
    at: database_backup_time,
    trigger: backup_glacier_trigger,
    interruptable: false,
  },
  {
    task: 'glacier:backup:files',
    frequency: 1.month,
    at: database_backup_time - 1.hours,
    trigger: glacier_files_backup_trigger,
    interruptable: false,
  },
]

job_type :rake_spot, 'cd :path && :environment_variable=:environment bundle exec rake :task --silent && echo capacity_provider:spot'

tasks.each do |task|
  next if task.key?(:trigger) && ! task[:trigger]

  options = {}
  options[:at] = task[:at] if task[:at].present?
  every task[:frequency], options do
    if ENV['ECS'] == 'true' && task[:interruptable]
      rake_spot task[:task]
    else
      rake task[:task]
    end
  end
end
