###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class EtoUpdateEverythingJob < BaseJob
    queue_as :low_priority

    def perform(start_date: 4.years.ago)
      # Ensure we know about all the available touch points
      GrdaWarehouse::HMIS::Assessment.update_touch_points

      # Fetch via QaaWS all the available
      EtoApi::Eto.site_identifiers.each do |identifier, _|
        Bo::ClientIdLookup.new(
          api_site_identifier: identifier,
          start_time: start_date,
        ).update_all!
      end

      # Break items remaining to fetch into 500 item chunks in delayed jobs
      GrdaWarehouse::EtoQaaws::ClientLookup.distinct.
        pluck(:client_id).each_slice(500) do |client_ids|
          Importing::EtoDemographicsJob.perform_later(client_ids: client_ids)
        end
      GrdaWarehouse::EtoQaaws::TouchPointLookup.distinct.
        pluck(:client_id).each_slice(500) do |client_ids|
          Importing::EtoTouchPointsJob.perform_later(client_ids: client_ids)
        end
    end

    def max_attempts
      1
    end
  end
end
