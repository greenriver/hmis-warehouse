namespace :messages do

  desc "Send all messages for users on the daily schedule"
  task daily: [:environment, "log:info_to_stdout"] do
    MessageJob.new('daily').perform
  end

  desc "Send all unsent messages"
  task all: [:environment, "log:info_to_stdout"] do
    MessageJob.new.perform
  end

end