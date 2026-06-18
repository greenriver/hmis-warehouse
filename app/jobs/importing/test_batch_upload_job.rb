###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
