# frozen_string_literal: true

module DelayedJobHelpers
  # Periodically calls work_off until no more jobs are ready to run.
  # This is safer than looping on a database count because it won't hang
  # if jobs are rescheduled for the future (e.g. during retries).
  #
  # If there are any jobs scheduled in the near future (default 30 seconds),
  # it will sleep until they are ready and try again.
  #
  # A safety counter (max_wait_iterations) is included to prevent infinite loops.
  def work_off_all_ready_jobs(max_wait: 30.seconds, max_wait_iterations: 10)
    worker = Delayed::Worker.new
    iterations = 0

    loop do
      loop do
        successes, failures = worker.work_off
        break if (successes + failures).zero?
      end

      next_job = Delayed::Job.queued.where(run_at: ..max_wait.from_now).order(:run_at).first
      break unless next_job

      iterations += 1
      if iterations > max_wait_iterations
        raise "work_off_all_ready_jobs exceeded max_wait_iterations (#{max_wait_iterations}). " \
              'Possible infinite loop detected with jobs scheduled in the near future.'
      end

      sleep_duration = next_job.run_at - Time.current
      sleep(sleep_duration) if sleep_duration.positive?
    end
  end
end
