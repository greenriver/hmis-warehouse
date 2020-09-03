###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class CombineEnrollments
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_log)
      project_ids = combined_project_ids(importer_log: importer_log)
      return unless project_ids.any?

      mark_incoming_data_as_do_not_import(importer_log: importer_log)

      # Combine enrollments from the import data source
      # NOTE: this operates on a single client at a single project, so there should be no overlapping enrollments
      project_ids.each do |project_id|
        enrollment_batch = []
        exit_batch = []
        # Process the clients in the project
        personal_ids = enrollment_scope(importer_log: importer_log, project_id: project_id).distinct.pluck(:PersonalID)
        personal_ids.each do |personal_id|
          last_enrollment = nil # The enrollment from the previous iteration of the find_each (or nil for the first)
          active_enrollment = nil # The first enrollment in the current set pf contiguous enrollments
          enrollment_scope(importer_log: importer_log, project_id: project_id).
            where(PersonalID: personal_id).
            order(EntryDate: :asc).
            find_each do |enrollment|
              if enrollment.exit.blank?
                # Pass through any open enrollments
                enrollment_batch << new_enrollment_from_enrollment(enrollment, importer_log)
              elsif last_enrollment.blank?
                # First enrollment enrollment with an exit
                active_enrollment = enrollment
              elsif enrollment.EntryDate != last_enrollment.exit.ExitDate
                # Non-contiguous enrollment, so close the current active enrollment, and start a new one
                enrollment_batch << new_enrollment_from_enrollment(active_enrollment, importer_log)
                exit_batch << new_exit_for_enrollment(last_enrollment.exit, active_enrollment, importer_log)

                active_enrollment = enrollment
                # else Contiguous enrollment, nothing to do
              end
              last_enrollment = enrollment
            end
          # Emit the remaining in-process enrollment
          enrollment_batch << new_enrollment_from_enrollment(active_enrollment, importer_log) if active_enrollment
          exit_batch << new_exit_for_enrollment(last_enrollment.exit, active_enrollment, importer_log) if last_enrollment.exit
        end

        # These are imported into the staging table, there is no uniqueness constraint, and existing data is marked as don't import
        # thus no need to check conflict targets
        enrollment_destination.import(enrollment_batch)
        exit_destination.import(exit_batch)
      end
    end

    def self.enrollment_scope(importer_log:, project_id:)
      enrollment_source.where(data_source_id: importer_log.data_source_id, ProjectID: project_id)
    end

    def self.new_enrollment_from_enrollment(source, importer_log)
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

    def self.new_exit_for_enrollment(source, enrollment, importer_log)
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

    def self.mark_incoming_data_as_do_not_import(importer_log:)
      project_ids = combined_project_ids(importer_log: importer_log)
      enrollment_destination.where(ProjectID: project_ids, importer_log_id: importer_log.id).
        update_all(should_import: false)

      e_t = enrollment_destination.arel_table
      exit_destination.joins(:enrollment).where(
        e_t[:ProjectID].in(project_ids),
        importer_log_id: importer_log.id,
      ).update_all(should_import: false)
    end

    # Remove any existing data that is covered by this import, but not included in the incoming data
    def self.remove_deleted_overlapping_data!(importer_log:, date_range:)
      project_ids = combined_project_ids(importer_log: importer_log)

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

    def self.copy_incoming_data!(importer_log:)
      project_ids = combined_project_ids(importer_log: importer_log)
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

    def self.combined_project_ids(importer_log:)
      project_source.enrollments_combined.
        where(data_source_id: importer_log.data_source_id).
        pluck(:ProjectID)
    end

    def self.project_source
      GrdaWarehouse::Hud::Project
    end

    def self.enrollment_source
      HmisCsvTwentyTwenty::Aggregated::Enrollment
    end

    def self.exit_source
      HmisCsvTwentyTwenty::Aggregated::Exit
    end

    def self.enrollment_destination
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def self.exit_destination
      HmisCsvTwentyTwenty::Importer::Exit
    end
  end
end
