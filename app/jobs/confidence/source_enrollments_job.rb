###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Confidence
  class SourceEnrollmentsJob < ConfidenceJob
    private def dm_model
      GrdaWarehouse::Confidence::SourceEnrollments
    end

    private def counts_for_batch(batch)
      counts_by_client_id = GrdaWarehouse::Hud::Client.where(id: @client_ids).joins(:source_enrollments).group(:id).count
      # Set up the data for the batch update
      batch.each do |record|
        record.value = counts_by_client_id[record.resource_id] || 0
      end
    end
  end
end
