namespace :jobs do
  desc "Check delayed job queue for hung jobs"
  task check_queue: [:environment] do
    CheckJobQueueJob.new.perform
  end
end