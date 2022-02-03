###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TestJob < BaseJob
  SLEEP_TIME = 5

  def perform(length_in_seconds: 10, memory_bloat_per_second: 10_000_000)
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

  def max_attempts
    1
  end
end
