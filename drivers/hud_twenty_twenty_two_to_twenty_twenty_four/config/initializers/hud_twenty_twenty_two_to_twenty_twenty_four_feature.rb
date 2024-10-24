# The core app (or other drivers) can check the presence of the
# HudTwentyTwentyTwoToTwentyTwentyFour driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:hud_twenty_twenty_two_to_twenty_twenty_four)
#
# use with caution!
RailsDrivers.loaded << :hud_twenty_twenty_two_to_twenty_twenty_four

Rails.application.reloader.to_prepare do
  # All of the CSVVersions we have seen for HUD 2022 files
  [
    '1.2',
    '2022',
    '2022 (v1.1 csv)',
    '2022 v1.2',
    'FY 2022 1.0',
    'FY2022',
    'FY2022v1.1',
    'Y2022',
    'v1.1',
    'v1.2',
  ].each do |version|
    Importers::HmisAutoMigrate.add_migration(version, 'HudTwentyTwentyTwoToTwentyTwentyFour::CsvTransformer')
  end

  Rails.application.config.queued_tasks[:hud_twenty_twenty_two_to_twenty_twenty_four_up] = -> do
    # If we've already migrated the data there will be some records in HmisParticipation or CeParticipation.
    # Since this process can't be cleanly run a second time, just exit if those already exist
    return if GrdaWarehouse::Hud::HmisParticipation.exists? || GrdaWarehouse::Hud::CeParticipation.exists?

    HudTwentyTwentyTwoToTwentyTwentyFour::DbTransformer.up

    # After the migration to FY2024, do some cleanup

    # Any exit record that has a new destination invalidates the cached one on the ServiceHistoryEnrollment record
    # queue those up for re-processing
    she_t = GrdaWarehouse::ServiceHistoryEnrollment.arel_table
    ex_t = GrdaWarehouse::Hud::Exit.arel_table
    GrdaWarehouse::Hud::Enrollment.joins(:exit, :service_history_enrollment).where(she_t[:destination].not_eq(ex_t[:Destination])).invalidate_processing!
    GrdaWarehouse::Tasks::ServiceHistory::Enrollment.queue_batch_process_unprocessed!
  end
end
