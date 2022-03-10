###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TestWorkoffJob < BaseJob
  SLEEP_TIME = 5

  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform(length_in_seconds: 500)
    start_time = Time.now
    while (Time.now - start_time) < length_in_seconds
      Rails.logger.info "Simulating... nothing."
      sleep SLEEP_TIME
    end
  end

  def max_attempts
    1
  end
end
