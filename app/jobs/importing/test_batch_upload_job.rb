###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class TestBatchUploadJob < BaseJob
    def perform
      GrdaWarehouse::HealthEmergency::TestBatch.un_started.each(&:process!)
    end

    def max_attempts
      2
    end
  end
end
