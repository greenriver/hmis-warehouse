# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Tasks
  class CleanupClientSearchQueriesTask
    RETENTION_PERIOD = 2.years

    def self.perform
      new.perform
    end

    def perform
      with_lock do
        GrdaWarehouseBase.transaction do
          cleanup_old_queries
        end
      end
    end

    protected

    def cleanup_old_queries
      cutoff_date = Time.current - RETENTION_PERIOD
      GrdaWarehouse::ClientSearchQuery.where(updated_at: ..cutoff_date).delete_all
    end

    def with_lock(&block)
      lock_name = self.class.name.demodulize
      GrdaWarehouseBase.with_advisory_lock(lock_name, timeout_seconds: 0, &block)
    end
  end
end
