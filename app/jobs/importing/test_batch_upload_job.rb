###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Importing
  class TestBatchUploadJob < BaseJob
    queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

    def perform
      GrdaWarehouse::HealthEmergency::TestBatch.un_started.each(&:process!)
    end

    def max_attempts
      2
    end
  end
end
