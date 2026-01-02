# frozen_string_literal: true

module DelayedJobHelpers
  def work_off_all_ready_jobs(...)
    DelayedJobHelpers.work_off_all_ready_jobs(...)
  end

  # Periodically calls work_off until no more jobs are ready to run.
  #
  # @param check_completion [Proc] An optional proc that returns boolean to stop waiting
  def self.work_off_all_ready_jobs(check_completion: nil, max_iterations: 100)
    worker = Delayed::Worker.new
    n = 0
    loop do
      n += 1
      break if n > max_iterations
      break if check_completion&.call

      successes, failures = worker.work_off
      total_processed = (successes + failures)
      break if total_processed.zero?
    end
  end
end
