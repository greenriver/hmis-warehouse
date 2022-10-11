###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module VeteranConfirmation
  class RateLimiter
    def initialize(interval = 60)
      @start_time = Time.now
      @interval = interval
    end

    def drain
      drain_time = Time.now
      elapsed = (drain_time - @start_time).floor # number of seconds, round down
      return if elapsed >= @interval # If we already blew through the interval, don't wait

      wait_time = @interval - elapsed # remaining time in interval
      sleep(wait_time)
    end
  end
end
