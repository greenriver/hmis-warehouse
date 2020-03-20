###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Importing
  class EtoUpdateEverythingJob < BaseJob
    queue_as :low_priority

    def initialize(start_date: 4.years.ago)
      @start_date = start_date
    end

    def perform
      # Ensure we know about all the available touch points
      GrdaWarehouse::HMIS::Assessment.update_touch_points

      # Fetch via QaaWS all the available
      EtoApi::Eto.site_identifiers.each do |identifier, _|
        Bo::ClientIdLookup.new(
          api_site_identifier: identifier,
          start_time: @start_date,
        ).update_all!
      end

      # Break items remaining to fetch into 500 item chunks in delayed jobs
      GrdaWarehouse::EtoQaaws::ClientLookup.pluck_in_batches(:client_id, batch_size: 500).each do |client_ids|
        Importing::EtoDemographicsJob.new(client_ids: client_ids).perform_later
      end
      GrdaWarehouse::EtoQaaws::TouchPointLookup.
        pluck_in_batches(:client_id, batch_size: 500).each do |client_ids|
          Importing::EtoDemographicsJob.new(touch_point_client_ids: client_ids).perform_later
        end
    end

    def max_attempts
      1
    end
  end
end
