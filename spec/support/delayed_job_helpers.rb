# frozen_string_literal: true

module DelayedJobHelpers
  # Periodically calls work_off until no more jobs are ready to run.
  # This is safer than looping on a database count because it won't hang
  # if jobs are rescheduled for the future (e.g. during retries).
  def work_off_all_ready_jobs
    worker = Delayed::Worker.new
    loop do
      successes, failures = worker.work_off
      break if (successes + failures).zero?
    end
  end
end
