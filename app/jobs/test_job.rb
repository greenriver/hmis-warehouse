###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class TestJob < BaseJob
  def perform(length_in_seconds = 10)
    a = Time.now

    while (Time.now - a) < length_in_seconds
      Rails.logger.info "Simulating processing. In `#{STARTING_PATH}` directory."
      sleep 5
    end
  end

  def max_attempts
    1
  end
end
