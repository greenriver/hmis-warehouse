###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Prepares an invalidated destination client for a service history rebuild without removing the
# rows the rebuild is about to replace.
#
# Each enrollment's rebuild (Enrollment#create_service_history!) deletes and re-inserts that
# enrollment's entry and exit rows in one transaction, so the client's valid service history stays
# readable until it is replaced. Rows the rebuild will never replace (the enrollment was deleted,
# its project or data source is gone, or its source client now belongs to another destination) are
# deleted here, so the end state after the rebuild matches a full delete-and-rebuild.
#
# Does not touch WarehouseClientsProcessed; the caller has already invalidated the client.
module GrdaWarehouse::Tasks::ServiceHistory
  class InvalidateClientInPlace
    include ArelHelper

    # Record types removed by Client#force_full_service_history_rebuild
    ENROLLMENT_RECORD_TYPES = [:entry, :exit].freeze
    # Legacy per-day rows on service_history_enrollments; days now live in service_history_services
    # and the enrollment rebuild doesn't replace these, so they are removed for every enrollment
    LEGACY_DAY_RECORD_TYPES = [:service, :extrapolated].freeze

    attr_reader :client

    # @param client [GrdaWarehouse::Hud::Client] a destination client
    def initialize(client)
      @client = client
    end

    def run!
      # No per-client lock: queue_clients serializes callers under ServiceHistory::Builder::ADVISORY_LOCK_NAME,
      # and running alongside Client#force_full_service_history_rebuild is harmless (both only delete this
      # client's rows and clear processed_as). Sharing that method's lock would make it skip silently.
      # source_enrollments spans data sources, so this can deadlock with an import updating or soft-deleting Enrollment rows
      GrdaWarehouseBase.retry_on_deadlock("invalidate in place client #{client.id}") do
        delete_rows_the_rebuild_will_not_replace
        client.source_enrollments.update_all(processed_as: nil)
      end
    end

    private def delete_rows_the_rebuild_will_not_replace
      client_service_history.where(record_type: LEGACY_DAY_RECORD_TYPES).delete_all

      existing_keys = client_service_history.
        where(record_type: ENROLLMENT_RECORD_TYPES).
        distinct.
        pluck(:data_source_id, :enrollment_group_id, :project_id)
      orphaned_keys = existing_keys - rebuildable_keys

      orphaned_keys.each do |data_source_id, enrollment_group_id, project_id|
        orphaned_rows = client_service_history.where(
          record_type: ENROLLMENT_RECORD_TYPES,
          data_source_id: data_source_id,
          enrollment_group_id: enrollment_group_id,
          project_id: project_id,
        )
        # Day rows are removed by the foreign key cascade
        orphaned_rows.delete_all
      end
    end

    # Keys of the client's source enrollments that Enrollment#rebuild_service_history! will rebuild:
    # it refuses enrollments without a project or data source, or entered before EARLIEST_ALLOWED_DATE
    private def rebuildable_keys
      earliest_allowed_date = GrdaWarehouse::Tasks::ServiceHistory::Enrollment::EARLIEST_ALLOWED_DATE

      client.source_enrollments.
        joins(:project, :data_source).
        where(e_t[:EntryDate].gteq(earliest_allowed_date)).
        distinct.
        pluck(e_t[:data_source_id], e_t[:EnrollmentID], e_t[:ProjectID])
    end

    private def client_service_history
      GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: client.id)
    end
  end
end
