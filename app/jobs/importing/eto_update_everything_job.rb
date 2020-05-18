###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class EtoUpdateEverythingJob < BaseJob
    queue_as :low_priority

    def perform(start_date: 4.years.ago, data_source_id:)
      # Ensure we know about all the available touch points
      GrdaWarehouse::HMIS::Assessment.update_touch_points

      Bo::ClientIdLookup.new(
        data_source_id: data_source_id,
        start_time: start_date.to_date,
      ).update_all!

      # Break items remaining to fetch into 500 item chunks in delayed jobs
      GrdaWarehouse::EtoQaaws::ClientLookup.distinct.
        where(data_source_id: data_source_id).
        pluck(:client_id).each_slice(500) do |client_ids|
          Importing::EtoDemographicsJob.perform_later(client_ids: client_ids)
        end
      GrdaWarehouse::EtoQaaws::TouchPointLookup.distinct.
        where(data_source_id: data_source_id).
        pluck(:client_id).each_slice(500) do |client_ids|
          Importing::EtoTouchPointsJob.perform_later(client_ids: client_ids)
        end
    end

    def max_attempts
      1
    end
  end
end
