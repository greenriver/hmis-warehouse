###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# One-time cleanup of aggregated enrollments/exits left behind when a source file changed the PersonalID on an EnrollmentID
# The PersonalID to keep is the one on the most recent loaded Enrollment row (importer_log_id isn't refreshed on an
# in-place upsert, so it can't be used to tell which row is current). Rows are only removed when an aggregated row
# with the current PersonalID exists, and EnrollmentIDs with no loader row are left alone.
# rails driver:hmis_csv_importer:cleanup_superseded_aggregated_personal_ids_20261002[true] # dry run (default), all data sources
# rails driver:hmis_csv_importer:cleanup_superseded_aggregated_personal_ids_20261002[true,200040] # dry run, one data source
# rails driver:hmis_csv_importer:cleanup_superseded_aggregated_personal_ids_20261002[false,200040]
desc 'One-time: remove aggregated enrollments/exits whose PersonalID was superseded by a later import'
task :cleanup_superseded_aggregated_personal_ids_20261002, [:dry_run, :data_source_id] => [:environment] do |_task, args|
  dry_run = args[:dry_run] != 'false'
  data_source_filter = args[:data_source_id].present? ? "AND data_source_id = #{Integer(args[:data_source_id])}" : ''
  latest = <<~SQL
    WITH latest AS (
      SELECT DISTINCT ON (data_source_id, "EnrollmentID") data_source_id, "EnrollmentID", "PersonalID"
      FROM #{HmisCsvTwentyTwentySix::Loader::Enrollment.table_name}
      WHERE "DateDeleted" IS NULL #{data_source_filter}
      ORDER BY data_source_id, "EnrollmentID", loaded_at DESC, id DESC
    )
  SQL
  superseded = <<~SQL
    FROM hmis_aggregated_enrollments old_e
    JOIN latest
      ON latest.data_source_id = old_e.data_source_id
      AND latest."EnrollmentID" = old_e."EnrollmentID"
      AND latest."PersonalID" <> old_e."PersonalID"
    JOIN hmis_aggregated_enrollments new_e
      ON new_e.data_source_id = latest.data_source_id
      AND new_e."EnrollmentID" = latest."EnrollmentID"
      AND new_e."PersonalID" = latest."PersonalID"
  SQL
  connection = GrdaWarehouseBase.connection
  GrdaWarehouseBase.transaction do
    exits = connection.delete(<<~SQL)
      #{latest}
      DELETE FROM hmis_aggregated_exits
      WHERE id IN (
        SELECT x.id #{superseded}
        JOIN hmis_aggregated_exits x
          ON x.data_source_id = old_e.data_source_id
          AND x."EnrollmentID" = old_e."EnrollmentID"
          AND x."PersonalID" = old_e."PersonalID"
      )
    SQL
    enrollments = connection.delete(<<~SQL)
      #{latest}
      DELETE FROM hmis_aggregated_enrollments
      WHERE id IN (SELECT old_e.id #{superseded})
    SQL
    puts "#{dry_run ? 'Would delete' : 'Deleted'} #{enrollments} aggregated enrollments and #{exits} aggregated exits"
    raise ActiveRecord::Rollback if dry_run
  end
end
