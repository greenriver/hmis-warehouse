###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    # One-time rollout of indexes to busy production warehouse databases, run by the
    # :files_client_id_and_enrollment_household_id_indexes and :service_history_enrollment_household_index
    # TaskQueue tasks. Each run builds every missing index in INDEXES.
    #
    # Built here rather than in a migration because these tables are large and busy: a concurrent
    # build waits for every older snapshot in the database (long reports included), so it can't
    # finish under a deploy's lock_timeout. Outside a deploy it can wait as long as it needs, and
    # waiting doesn't block reads or writes.
    #
    # Development and test get the same indexes from the Rails.env.local?-guarded migrations
    # 20261104120100_add_index_to_files_on_client_id,
    # 20261104120200_add_lower_household_id_index_to_enrollment and
    # 20261117160000_add_data_source_household_index_to_service_history_enrollments. Keep the definitions in sync.
    #
    # DISPOSABLE: once every staging and production database has completed both tasks, delete this
    # class, its spec, and the TaskQueue entries.
    #
    # Usage: GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes.run!
    class BuildFilesAndEnrollmentIndexes
      INDEXES = [
        # Client file lists and counts (warehouse and HMIS) filter on files.client_id.
        {
          table: :files,
          columns: :client_id,
          name: 'index_files_on_client_id',
        },
        # Hmis::Hud::Enrollment.matching_search_term's HouseholdID lookups:
        #   LOWER("Enrollment"."HouseholdID") LIKE 'abc123%'
        #   LOWER("Enrollment"."HouseholdID") = 'abc123...'
        # text_pattern_ops lets LIKE prefix searches use the index under a non-C collation, and it
        # still serves plain equality. The predicate matches the paranoid default scope.
        {
          table: :Enrollment,
          columns: 'lower("HouseholdID") text_pattern_ops',
          name: 'idx_enrollment_on_lower_household_id_pattern',
          where: '"DateDeleted" IS NULL',
        },
        # HUD report household lookups (HudApr::Generators::Shared::Fy2026::HouseholdHohEnrollments)
        # join head of household entries to the report's households on these columns.
        {
          table: :service_history_enrollments,
          columns: [:data_source_id, :household_id],
          name: 'index_she_on_ds_household_id_entry',
          where: "record_type = 'entry'",
        },
      ].freeze

      LOCK_NAME = 'GrdaWarehouse::Tasks::BuildFilesAndEnrollmentIndexes'

      def self.run!
        new.run!
      end

      # Builds one index at a time: the Enrollment index is partial and an expression index, so
      # any other concurrent build in the database would wait on it anyway.
      #
      # On a new database both TaskQueue keys can run at once. ensure_index! reads an index that is
      # still being built concurrently as invalid and would drop it, so only one run proceeds. The
      # other returns at once: every run builds the full INDEXES list. It must not wait in
      # pg_advisory_lock either, since CREATE INDEX CONCURRENTLY waits for that statement to end.
      def run!
        acquired = GrdaWarehouseBase.with_advisory_lock(LOCK_NAME, timeout_seconds: 0) do
          INDEXES.each { |index| ensure_index!(**index) }
          true
        end
        Rails.logger.info("#{LOCK_NAME}: another run holds the lock; skipping") unless acquired
      end

      private

      # Idempotent:
      # - valid index exists: do nothing
      # - invalid index (a failed concurrent build): drop it and rebuild
      # - no index: build it
      def ensure_index!(table:, columns:, name:, **options)
        validity = index_validity(name)
        return if validity == true

        connection.remove_index(table, name: name, algorithm: :concurrently) if validity == false

        connection.add_index(
          table,
          columns,
          name: name,
          algorithm: :concurrently,
          **options,
        )
      end

      # true (valid), false (invalid), or nil (no such index)
      def index_validity(name)
        sql = <<~SQL
          SELECT i.indisvalid
          FROM pg_index i
          JOIN pg_class c ON c.oid = i.indexrelid
          WHERE c.relname = #{connection.quote(name)}
        SQL
        connection.select_value(sql)
      end

      def connection
        GrdaWarehouseBase.connection
      end
    end
  end
end
