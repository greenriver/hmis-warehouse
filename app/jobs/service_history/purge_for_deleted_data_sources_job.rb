# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ServiceHistory
  class PurgeForDeletedDataSourcesJob < BaseJob
    queue_as ENV.fetch('DJ_LONG_QUEUE_NAME', :long_running)

    # @param dry_run [Boolean] When true, only counts records that would be deleted
    # @param retain_at [DateTime] Only purge data sources deleted before this date
    def perform(dry_run: false, retain_at: 1.day.ago)
      GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call(
        dry_run: dry_run,
        retain_at: retain_at,
      )
    end
  end
end
