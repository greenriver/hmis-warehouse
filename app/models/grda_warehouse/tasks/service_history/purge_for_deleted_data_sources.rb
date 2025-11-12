# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Purges service history records (ServiceHistoryEnrollment and ServiceHistoryService)
# for soft-deleted data sources.
#
#  The purge task:
#  - Finds data sources that have been soft-deleted (have a `deleted_at` timestamp)
#  - Only processes data sources deleted before a retention period (default: 1 day ago)
#  - Deletes all `ServiceHistoryService` records for those data sources (from all partitions)
#  - Deletes all `ServiceHistoryEnrollment` records for those data sources
#
# Usage:
#   GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call
#   GrdaWarehouse::Tasks::ServiceHistory::PurgeForDeletedDataSources.call(retain_at: 2.days.ago)
#
module GrdaWarehouse::Tasks::ServiceHistory
  class PurgeForDeletedDataSources
    include NotifierConfig
    include ArelHelper

    def self.call(retain_at: 24.hours.ago)
      new(retain_at: retain_at).call
    end

    def initialize(retain_at:)
      @retain_at = retain_at
      setup_notifier('Purge Service History for Deleted Data Sources')
    end

    def call
      deleted_data_source_ids = find_deleted_data_sources
      return { enrollments_deleted: 0, services_deleted: 0 } if deleted_data_source_ids.empty?

      log "Found #{deleted_data_source_ids.size} deleted data source(s) with service history records"

      # Delete services first, then enrollments (services reference enrollments)
      services_deleted = purge_service_history_services(deleted_data_source_ids)
      enrollments_deleted = purge_service_history_enrollments(deleted_data_source_ids)

      log "Purged #{services_deleted} service history service records"
      log "Purged #{enrollments_deleted} service history enrollment records"

      {
        enrollments_deleted: enrollments_deleted,
        services_deleted: services_deleted,
      }
    end

    private

    def find_deleted_data_sources
      # Find data sources that:
      # 1. Have been soft-deleted (deleted_at is present)
      # 2. Were deleted before the retention date
      GrdaWarehouse::DataSource.
        with_deleted.
        where.not(deleted_at: nil).
        where(deleted_at: ..@retain_at).
        pluck(:id)
    end

    def purge_service_history_enrollments(data_source_ids)
      return 0 if data_source_ids.empty?

      GrdaWarehouse::ServiceHistoryEnrollment.
        where(data_source_id: data_source_ids).
        delete_all
    end

    def purge_service_history_services(data_source_ids)
      return 0 if data_source_ids.empty?

      enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.
        where(data_source_id: data_source_ids)

      count = 0
      enrollment_scope.in_batches(of: 1000) do |batch|
        enrollment_ids = batch.pluck(:id)
        next if enrollment_ids.empty?

        count += GrdaWarehouse::ServiceHistoryService.
          where(service_history_enrollment_id: enrollment_ids).
          delete_all
      end
      count
    end

    def log(message)
      Rails.logger.info(message)
      @notifier&.ping(message) if defined?(@notifier)
    end
  end
end
