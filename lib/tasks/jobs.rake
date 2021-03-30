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

  desc "fill the queue test"
  task :fill_queue, [] => [:environment] do |t, args|
    200.times do
      TestJob.perform_later(length_in_seconds: 60, memory_bloat_per_second: 10)
    end
  end
end
