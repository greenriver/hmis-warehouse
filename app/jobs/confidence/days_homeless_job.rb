###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Confidence
  class DaysHomelessJob < ConfidenceJob
    private def dm_model
      GrdaWarehouse::Confidence::DaysHomeless
    end

    private def counts_for_batch(batch)
      # get lists of dates for the provided client
      # ids where they have only homeless services
      # This is a batch version of GrdaWarehouse::Hud::Client.dates_homeless_scope
      dates_by_client_id = {}
      t = GrdaWarehouse::ServiceHistoryService.arel_table
      GrdaWarehouse::ServiceHistoryService.where(
        client_id: @client_ids,
      ).where(
        t[:date].lteq(Date.current),
      ).group(:client_id, :date).having(
        # If all answers are nil, then not homeless
        # If any answers are not nil, and any answers are false, then not homeless
        # If any answers are not nil, and all answers are true, then homeless
        Arel.sql('every(homeless)'),
      ).pluck(:client_id, :date).each do |client_id, date|
        dates_by_client_id[client_id] ||= []
        dates_by_client_id[client_id] << date
      end
      # Create the data object to power the bulk update
      batch.each do |record|
        dates = dates_by_client_id[record.resource_id] || []
        record.value = dates.select { |date| date <= record.census }.count
      end
    end
  end
end
