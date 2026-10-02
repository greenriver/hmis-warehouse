###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# One-time cleanup of aggregated enrollments/exits left behind when a source file changed the PersonalID on an EnrollmentID
# rails driver:hmis_csv_importer:cleanup_superseded_aggregated_personal_ids_20261002[true] # dry run (default)
# rails driver:hmis_csv_importer:cleanup_superseded_aggregated_personal_ids_20261002[false]
desc 'One-time: remove aggregated enrollments/exits whose PersonalID was superseded by a later import'
task :cleanup_superseded_aggregated_personal_ids_20261002, [:dry_run] => [:environment] do |_task, args|
  dry_run = args[:dry_run] != 'false'
  superseded = <<~SQL
    FROM hmis_aggregated_enrollments old_e
    JOIN hmis_aggregated_enrollments new_e
      ON new_e.data_source_id = old_e.data_source_id
      AND new_e."EnrollmentID" = old_e."EnrollmentID"
      AND new_e."PersonalID" <> old_e."PersonalID"
      AND new_e.importer_log_id > old_e.importer_log_id
  SQL
  connection = GrdaWarehouseBase.connection
  GrdaWarehouseBase.transaction do
    exits = connection.delete(<<~SQL)
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
      DELETE FROM hmis_aggregated_enrollments
      WHERE id IN (SELECT old_e.id #{superseded})
    SQL
    puts "#{dry_run ? 'Would delete' : 'Deleted'} #{enrollments} aggregated enrollments and #{exits} aggregated exits"
    raise ActiveRecord::Rollback if dry_run
  end
end
