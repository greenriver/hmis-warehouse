###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    # Drops the indexes on pending_date_deleted and a duplicate Enrollment ExportID index, run by
    # the :drop_importer_pending_deletion_indexes TaskQueue task. Nothing reads pending_date_deleted
    # any more, so the indexes only add write cost to every import. The column and its stale values
    # stay: clearing them would be a large unbatched UPDATE and they are harmless unread.
    #
    # Must run after the importer code that stopped reading pending_date_deleted is deployed, since
    # the previous importer filters on it. TaskQueue tasks run after a deploy.
    #
    # Development and test drop the same indexes in the Rails.env.local?-guarded migration
    # DropImporterPendingDeletionIndexes. Keep the definitions in sync.
    #
    # DISPOSABLE: once every staging and production database has completed the task, delete this
    # class, its spec, and the TaskQueue entry.
    #
    # Usage: GrdaWarehouse::Tasks::DropImporterPendingDeletionIndexes.run!
    class DropImporterPendingDeletionIndexes
      INDEXES = [
        { table: :ClientUnencrypted, name: 'ClientUnencrypted_pending_date_deleted_idx' },
        { table: :Affiliation, name: 'index_Affiliation_on_pending_date_deleted' },
        { table: :AssessmentQuestions, name: 'index_AssessmentQuestions_on_pending_date_deleted' },
        { table: :AssessmentResults, name: 'index_AssessmentResults_on_pending_date_deleted' },
        { table: :Assessment, name: 'index_Assessment_on_pending_date_deleted' },
        { table: :Client, name: 'index_Client_on_pending_date_deleted' },
        { table: :CurrentLivingSituation, name: 'index_CurrentLivingSituation_on_pending_date_deleted' },
        { table: :Disabilities, name: 'index_Disabilities_on_pending_date_deleted' },
        { table: :EmploymentEducation, name: 'index_EmploymentEducation_on_pending_date_deleted' },
        { table: :EnrollmentCoC, name: 'index_EnrollmentCoC_on_pending_date_deleted' },
        { table: :Enrollment, name: 'index_Enrollment_on_pending_date_deleted' },
        { table: :Event, name: 'index_Event_on_pending_date_deleted' },
        { table: :Exit, name: 'index_Exit_on_pending_date_deleted' },
        { table: :Funder, name: 'index_Funder_on_pending_date_deleted' },
        { table: :Geography, name: 'index_Geography_on_pending_date_deleted' },
        { table: :HealthAndDV, name: 'index_HealthAndDV_on_pending_date_deleted' },
        { table: :IncomeBenefits, name: 'index_IncomeBenefits_on_pending_date_deleted' },
        { table: :Inventory, name: 'index_Inventory_on_pending_date_deleted' },
        { table: :Organization, name: 'index_Organization_on_pending_date_deleted' },
        { table: :ProjectCoC, name: 'index_ProjectCoC_on_pending_date_deleted' },
        { table: :Project, name: 'index_Project_on_pending_date_deleted' },
        { table: :Services, name: 'index_Services_on_pending_date_deleted' },
        { table: :User, name: 'index_User_on_pending_date_deleted' },
        # Duplicate of enrollment_export_id, which stays.
        { table: :Enrollment, name: 'Enrollment_634d' },
      ].freeze

      LOCK_NAME = 'GrdaWarehouse::Tasks::DropImporterPendingDeletionIndexes'

      def self.run!
        new.run!
      end

      # DROP INDEX CONCURRENTLY waits for conflicting transactions, so a second run returns at once
      # instead of queueing behind the first.
      def run!
        acquired = GrdaWarehouseBase.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
          INDEXES.each do |index|
            connection.remove_index(index[:table], name: index[:name], algorithm: :concurrently, if_exists: true)
          end
          true
        end
        Rails.logger.info("#{LOCK_NAME}: another run holds the lock; skipping") unless acquired
      end

      private

      def connection
        GrdaWarehouseBase.connection
      end
    end
  end
end
