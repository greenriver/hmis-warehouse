###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class CombineEnrollments < Base
    INSERT_BATCH_SIZE = 2_000

    def aggregate!
      project_ids = combined_project_ids
      return unless project_ids.any?

      mark_incoming_data_as_do_not_import

      # Combine enrollments from the import data source
      # NOTE: this operates on a single client at a single project, so there should be no overlapping enrollments
      # This will loop through all enrollments for a client and send back to the import tables any that overlap the import range
      # in an aggregated form.
      # NOTE: associated assessments (HealthAndDV, IncomeBenefit, etc.) will be imported for all enrollments
      # but won't be accessible via the UI.  The Exit assessment associated data will be from the initial exit
      # (tied to the initial enrollment) while the exit record will come from the final enrollment in the group.
      # In the future we may want to include associated data that is flagged as
      # DataCollectionStage 3 (Project exit) that comes specifically from the Exit record included.
      # If this is implemented, we would also need to exclude the associated data flagged as
      # DataCollectionStage 3 that previously was associated with the initial enrollment.
      project_ids.each do |project_id|
        enrollment_batch = []
        exit_batch = []
        # Process the clients in the project
        personal_ids = enrollment_scope(project_id: project_id).distinct.pluck(:PersonalID)
        personal_ids.each do |personal_id|
          last_enrollment = nil # The enrollment from the previous iteration of the find_each (or nil for the first)
          active_enrollment = nil # The first enrollment in the current set pf contiguous enrollments
          enrollment_scope(project_id: project_id).
            where(PersonalID: personal_id).
            preload(:exit).
            order(EntryDate: :asc).
            find_each do |enrollment|
              if enrollment.exit.blank?
                # Pass through any open enrollments
                enrollment_batch << new_enrollment_from_enrollment(enrollment) if enrollment_during_date_range?(enrollment.EntryDate)
                next
              elsif last_enrollment.blank?
                # First enrollment enrollment with an exit
                active_enrollment = enrollment
              elsif enrollment.EntryDate != last_enrollment.exit.ExitDate
                # Non-contiguous enrollment, so close the current active enrollment, and start a new one
                enrollment_batch << new_enrollment_from_enrollment(active_enrollment) if enrollment_during_date_range?(active_enrollment.EntryDate, active_enrollment.exit&.ExitDate)
                exit_batch << new_exit_for_enrollment(last_enrollment.exit, active_enrollment) if enrollment_during_date_range?(active_enrollment.EntryDate, last_enrollment.exit&.ExitDate)

                active_enrollment = enrollment
                # else Contiguous enrollment, nothing to do
              end
              last_enrollment = enrollment
            end
          # Emit the remaining in-process enrollment
          enrollment_batch << new_enrollment_from_enrollment(active_enrollment) if active_enrollment && enrollment_during_date_range?(active_enrollment.EntryDate, active_enrollment.exit&.ExitDate)
          exit_batch << new_exit_for_enrollment(last_enrollment.exit, active_enrollment) if last_enrollment&.exit && enrollment_during_date_range?(active_enrollment.EntryDate, last_enrollment.exit&.ExitDate)
        end

        # These are imported into the staging table, there is no uniqueness constraint, and existing data is marked as don't import
        # thus no need to check conflict targets
        enrollment_destination.import(enrollment_batch)
        exit_destination.import(exit_batch)
      end
    end

    # Only send back the aggregated enrollments that overlap with the range specified
    def enrollment_during_date_range?(entry_date, exit_date = nil)
      exit_date ||= Date.current
      date_range.range.overlaps?(entry_date..exit_date)
    end

    def enrollment_scope(project_id:)
      enrollment_source.where(data_source_id: importer_log.data_source_id, ProjectID: project_id)
    end

    def new_enrollment_from_enrollment(source)
      source_data = source.slice(enrollment_source.hmis_structure(version: '2020').keys)
      new_enrollment = enrollment_destination.new(
        source_data.merge(
          source_type: source.class.name,
          source_id: source.id,
          data_source_id: source.data_source_id,
          importer_log_id: importer_log.id,
          pre_processed_at: Time.current,
        ),
      )
      new_enrollment.set_source_hash

      new_enrollment
    end

    def new_exit_for_enrollment(source, enrollment)
      source_data = source.slice(exit_source.hmis_structure(version: '2020').keys)
      new_exit = exit_destination.new(
        source_data.merge(
          source_type: source.class.name,
          source_id: source.id,
          data_source_id: source.data_source_id,
          EnrollmentID: enrollment.EnrollmentID,
          importer_log_id: importer_log.id,
          pre_processed_at: Time.current,
        ),
      )
      new_exit.set_source_hash

      new_exit
    end

    def mark_incoming_data_as_do_not_import
      project_ids = combined_project_ids
      enrollment_destination.where(ProjectID: project_ids, importer_log_id: importer_log.id).
        update_all(should_import: false)

      e_t = enrollment_destination.arel_table
      exit_destination.joins(:enrollment).where(
        e_t[:ProjectID].in(project_ids),
        importer_log_id: importer_log.id,
      ).update_all(should_import: false)
    end

    # Remove any existing data that is covered by this import, but not included in the incoming data
    def remove_deleted_overlapping_data!
      project_ids = combined_project_ids

      ex_t = exit_source.arel_table

      incoming_enrollment_ids = enrollment_destination.where(
        ProjectID: project_ids,
        data_source_id: importer_log.data_source_id,
        importer_log_id: importer_log.id,
      ).pluck(:EnrollmentID)
      incoming_exit_ids = exit_destination.where(
        EnrollmentID: incoming_enrollment_ids,
        data_source_id: importer_log.data_source_id,
        importer_log_id: importer_log.id,
      ).pluck(:ExitID)

      enrollments_to_delete = enrollment_source.where(
        ProjectID: project_ids,
        data_source_id: importer_log.data_source_id,
      ).open_during_range(date_range.range).
        where.not(EnrollmentID: incoming_enrollment_ids).
        pluck(:id)
      exits_to_delete = enrollment_source.where(
        ProjectID: project_ids,
        data_source_id: importer_log.data_source_id,
      ).open_during_range(date_range.range).
        where.not(ex_t[:ExitID].in(incoming_exit_ids)).
        references(:exit).
        pluck(ex_t[:id]).compact

      enrollment_source.where(id: enrollments_to_delete).delete_all if enrollments_to_delete.any?
      exit_source.where(id: exits_to_delete).delete_all if exits_to_delete.any?
    end

    def copy_incoming_data!
      project_ids = combined_project_ids
      enrollment_destination.where(ProjectID: project_ids, importer_log_id: importer_log.id).
        find_in_batches do |batch|
          enrollments_batch = []
          batch.each do |enrollment|
            enrollments_batch << enrollment_source.new_from(enrollment)
          end
          enrollment_source.import_aggregated(enrollments_batch) if enrollments_batch.any?
        end

      exit_destination.joins(:enrollment).where(importer_log_id: importer_log.id).
        merge(enrollment_destination.where(ProjectID: project_ids, importer_log_id: importer_log.id)).
        find_in_batches do |batch|
          exits_batch = []
          batch.each do |exit_row|
            exits_batch << exit_source.new_from(exit_row)
          end
          exit_source.import_aggregated(exits_batch) if exits_batch.any?
        end
    end

    def rebuild_warehouse_data
      dest_clients = GrdaWarehouse::Hud::Client.destination.joins(:source_enrollments).
        merge(
          GrdaWarehouse::Hud::Enrollment.where(
            data_source_id: importer_log.data_source_id,
            ProjectID: combined_project_ids,
          ),
        ).distinct.pluck(:id)
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: dest_clients).run!
    end

    def combined_project_ids
      project_source.enrollments_combined.
        where(data_source_id: importer_log.data_source_id).
        where(ProjectID: enrollment_destination.where(importer_log_id: importer_log.id).select(:ProjectID)).
        pluck(:ProjectID)
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def enrollment_source
      HmisCsvTwentyTwenty::Aggregated::Enrollment
    end

    def exit_source
      HmisCsvTwentyTwenty::Aggregated::Exit
    end

    def enrollment_destination
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def exit_destination
      HmisCsvTwentyTwenty::Importer::Exit
    end

    def self.description
      'Replace multiple contiguous enrollments (the next entry falls immediately after the previous exit) with a single enrollment.'
    end

    def self.enable
      {
        import_aggregators: {
          'Enrollment': ['HmisCsvTwentyTwenty::Aggregated::CombineEnrollments'],
        },
      }
    end
  end
end
