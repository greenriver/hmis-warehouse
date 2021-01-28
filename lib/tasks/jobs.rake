namespace :jobs do
  desc "Check delayed job queue for hung jobs"
  task check_queue: [:environment] do
    CheckJobQueue.new.perform
  end

  desc "Spin up workoff container if needed"
  task arbitrate_workoff: [:environment] do
    arbiter = WorkoffArbiter.new
    if arbiter.needs_worker?
      arbiter.add_worker!
    end
  end
end
