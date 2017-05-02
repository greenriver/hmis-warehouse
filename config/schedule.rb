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
every 1.day, at: '9:30 am' do
  rake "grda_warehouse:daily"
end

every 1.day, at: '2:30 am' do
  command "cd /u/apps/boston-hmis/current && backup perform -t hmis --config-file /u/apps/boston-hmis/current/backup/models/hmis.rb"
end

every 1.day, at: '4:00 pm' do
  rake "eto:import:demographics"
end