# frozen_string_literal: true

module DelayedJobHelpers
  def work_off_all_ready_jobs(...)
    DelayedJobHelpers.work_off_all_ready_jobs(...)
  end

  # Calls work_off until no more jobs are ready to run.
  def self.work_off_all_ready_jobs(job_limit: 1_000)
    worker = Delayed::Worker.new
    successes, failures = worker.work_off(job_limit)
    (successes + failures)
  end
end
