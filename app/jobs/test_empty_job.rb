###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class TestEmptyJob < BaseJob
  def perform
    Rails.logger.info 'TestEmptyJob started'
    Rails.logger.info 'TestEmptyJob completed'
  end

  def max_attempts
    1
  end
end
