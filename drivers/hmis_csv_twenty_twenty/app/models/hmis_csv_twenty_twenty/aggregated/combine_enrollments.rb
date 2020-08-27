###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::Aggregated
  class CombineEnrollments
    INSERT_BATCH_SIZE = 2_000

    def self.aggregate!(importer_log)
      project_ids = project_source.
        where(combine_enrollments: true, data_source_id: importer_log.data_source_id).
        pluck(:ProjectID)

      # Pass through the enrollments from this import that aren't related to the projects requiring combining enrollments
      emit_unrelated_enrollments(project_ids, importer_log)

      # Combine enrollments from the import data source
      enrollment_scope = enrollment_source.where(data_source_id: importer_log.data_source_id)

      project_ids.each do |project_id|
        enrollment_batch = []
        exit_batch = []
        # Process the clients in the project
        personal_ids = enrollment_scope.where(ProjectID: project_id).distinct.pluck(:PersonalID)
        personal_ids.each do |personal_id|
          last_enrollment = nil # The enrollment from the previous iteration of the find_each (or nil for the first)
          active_enrollment = nil # The first enrollment in the current set pf contiguous enrollments
          enrollment_scope.
            where(ProjectID: project_id, PersonalID: personal_id).
            order(EntryDate: :asc).
            find_each do |enrollment|
              if enrollment.exit.blank?
                # Pass through any open enrollments
                enrollment_batch << enrollment.dup
              elsif last_enrollment.blank?
                # First enrollment enrollment with an exit
                active_enrollment = enrollment
              elsif enrollment.EntryDate != last_enrollment.exit.ExitDate
                # Non-contiguous enrollment, so close the current active enrollment, and start a new one
                enrollment_batch << active_enrollment.dup
                exit_batch << new_exit_from(last_enrollment.exit, active_enrollment, importer_log)

                active_enrollment = enrollment
                # else Contiguous enrollment, nothing to do
              end
              last_enrollment = enrollment
            end
          # Emit the remaining in-process enrollment
          enrollment_batch << active_enrollment.dup
          exit_batch << new_exit_from(last_enrollment.exit, active_enrollment, importer_log)
        end

        # These are imported into the staging table, there is no uniqueness constraint, and no existing data
        # thus no need to check conflict targets
        if enrollment_destination.respond_to?(:import_aggregated)
          enrollment_destination.import_aggregated(enrollment_batch)
        else
          enrollment_destination.import(enrollment_batch)
        end
        if exit_destination.respond_to?(:import_aggregated)
          exit_destination.import_aggregated(exit_batch)
        else
          exit_destination.import(exit_batch)
        end
      end
    end

    def self.emit_unrelated_enrollments(project_ids, importer_log)
      batch = []
      enrollment_source.
        where(importer_log_id: importer_log.id).
        where.not(ProjectID: project_ids).
        find_each do |enrollment|
        destination = new_enrollment_from(enrollment, importer_log)

        batch << destination

        if batch.count >= INSERT_BATCH_SIZE
          # These are imported into the staging table, there is no uniqueness constraint, and no existing data
          # thus no need to check conflict targets
          if enrollment_destination.respond_to?(:import_aggregated)
            enrollment_destination.import_aggregated(batch)
          else
            enrollment_destination.import(batch)
          end
          batch = []
        end
      end
      return unless batch.present?

      # These are imported into the staging table, there is no uniqueness constraint, and no existing data
      # thus no need to check conflict targets
      if enrollment_destination.respond_to?(:import_aggregated)
        enrollment_destination.import_aggregated(batch)
      else
        enrollment_destination.import(batch)
      end
    end

    def self.new_enrollment_from(source, importer_log)
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

    def self.new_exit_from(source, enrollment, importer_log)
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
