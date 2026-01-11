# frozen_string_literal: true

module DelayedJobHelpers
  def work_off_all_ready_jobs(...)
    DelayedJobHelpers.work_off_all_ready_jobs(...)
  end

  # Calls work_off until no more jobs are ready to run or the limit is reached.
  # We cap at 1,000 iterations to avoid infinite loops from self-enqueuing jobs.
  def self.work_off_all_ready_jobs(job_limit: 1_000)
    total_processed = 0
    Delayed::Job.uncached do
      worker = Delayed::Worker.new

      until total_processed >= job_limit
        # Handling potential clock skew in CI by forcing jobs to be ready
        Delayed::Job.where(run_at: Time.current..).update_all(run_at: 1.minute.ago)

        successes, failures = worker.work_off(job_limit - total_processed)
        processed_this_pass = successes + failures
        total_processed += processed_this_pass

        # check for remaining jobs
        break unless Delayed::Job.where(failed_at: nil).exists?

        # Stop if no progress was made to avoid infinite loop (e.g. locked jobs)
        break if processed_this_pass.zero?

        # Allow for any DB propagation or async enqueues
        sleep(0.01)
      end
    end

    total_processed
  end
end
