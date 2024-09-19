###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TestJob < BaseJob
  SLEEP_TIME = 5

  def self.simulate
    60.times do
      TestJob.perform_later(length_in_seconds: Random.rand(60), simulate_failure: Random.rand < 0.2)
    end
  end

  def perform(length_in_seconds: 10, memory_bloat_per_second: 10_000_000, simulate_failure: false)
    Rails.logger.info 'TestJob started and has a log message in the job'
    Rails.logger.tagged({ process_name: 'testjob' }) do
      Rails.logger.info 'tagged with process_name=testjob'
    end
    Rails.logger.tagged([{ process_name: 'testjob' }]) do
      Rails.logger.info 'tagged with process_name=testjob'
    end
    Rails.logger.info 'NOT tagged'

    raise 'Whoops. A test failure just occured' if simulate_failure

    setup_notifier('TestJob')
    @notifier.ping('Testing!') if @send_notifications
    a = Time.now

    bloater = {}

    while (Time.now - a) < length_in_seconds
      Rails.logger.info "Simulating processing. In `#{STARTING_PATH}` directory."
      bloater[Random.rand.to_s] = Array.new(memory_bloat_per_second * SLEEP_TIME) if memory_bloat_per_second
      sleep SLEEP_TIME
    end
  end

  def queue_name
    ['mailers', nil, 'long_running', 'default_priority', 'short_running'].sample
  end

  def max_attempts
    1
  end
end
