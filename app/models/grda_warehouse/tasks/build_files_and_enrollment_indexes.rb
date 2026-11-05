###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse
  module Tasks
    # One-time rollout of two indexes to busy production warehouse databases, run by the
    # :files_client_id_and_enrollment_household_id_indexes TaskQueue task.
    #
    # Built here rather than in a migration because both tables are large and busy: a concurrent
    # build waits for every older snapshot in the database (long reports included), so it can't
    # finish under a deploy's lock_timeout. Outside a deploy it can wait as long as it needs, and
    # waiting doesn't block reads or writes.
    #
    # DISPOSABLE: once every production database has completed the task and follow-up migrations
    # (guarded on a valid index existing) put these indexes in warehouse_structure.sql, delete this
    # class, its spec, and the TaskQueue entry.
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
      ].freeze

      def self.run!
        new.run!
      end

      # Builds one index at a time: the Enrollment index is partial and an expression index, so
      # any other concurrent build in the database would wait on it anyway.
      def run!
        INDEXES.each { |index| ensure_index!(**index) }
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
