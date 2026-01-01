# frozen_string_literal: true

module DelayedJobHelpers
  def work_off_all_ready_jobs(...)
    DelayedJobHelpers.work_off_all_ready_jobs(...)
  end

  # Periodically calls work_off until no more jobs are ready to run.
  # Pulls future-scheduled jobs (like retries) forward to run immediately.
  #
  # @param check_completion [Proc] An optional proc that returns boolean to stop waiting
  def self.work_off_all_ready_jobs(check_completion: nil, max_iterations: 100)
    worker = Delayed::Worker.new
    n = 0
    loop do
      n += 1
      raise 'safety count exceeded work_off_all_ready_jobs' if n > max_iterations

      successes, failures = worker.work_off
      total_processed = (successes + failures)

      break if check_completion&.call

      # Loop again if we did some work
      next if total_processed > 0

      # No work done, pull forward any pending jobs rescheduled for the future
      now = Time.current
      pending = Delayed::Job.where(failed_at: nil).
        where('run_at > ?', now).
        order(:run_at, :id).first
      pending&.update!(run_at: now)

      break if pending.nil?
    end
  end
end
