namespace :messages do

  desc "Send all messages for users on the daily schedule"
  task :daily do
    MessageJob.new('daily').perform
  end

  desc "Send all unsent messages"
  task :all do
    MessageJob.new.perform
  end

end