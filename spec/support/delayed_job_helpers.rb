# frozen_string_literal: true

module DelayedJobHelpers
  def work_off_all_ready_jobs(...)
    DelayedJobHelpers.work_off_all_ready_jobs(...)
  end

  # Calls work_off until no more jobs are ready to run.
  def self.work_off_all_ready_jobs(job_limit: 1_000)
    worker = Delayed::Worker.new
    total_processed = 0

    # We loop because some jobs may enqueue others.
    # We cap at 1,000 iterations to avoid infinite loops
    1_000.times do
      break if Delayed::Job.uncached { Delayed::Job.where(failed_at: nil).count.zero? }
      break if total_processed >= job_limit

      successes, failures = worker.work_off(job_limit - total_processed)
      total_processed += (successes + failures)
      sleep(0.03) # Short sleep to allow for any DB propagation or async enqueues
    end

    total_processed
  end
end
