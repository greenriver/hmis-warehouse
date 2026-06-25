###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class TestEmptyJob < BaseJob
  queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

  def perform
    Rails.logger.info 'TestEmptyJob started'
    Rails.logger.info 'TestEmptyJob completed'
  end

  def max_attempts
    1
  end
end
