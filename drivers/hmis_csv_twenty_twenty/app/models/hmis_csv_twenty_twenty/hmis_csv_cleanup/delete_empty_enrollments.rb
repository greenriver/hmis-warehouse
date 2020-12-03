###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class DeleteEmptyEnrollments < Base
    def cleanup!
      enrollment_batch = []

      enrollments_with_no_service = enrollment_scope.where.not(id: enrollment_scope.joins(:services).select(:id))
      enrollments_with_no_cls = enrollment_scope.where.not(id: enrollment_scope.joins(:current_living_situations).select(:id))
      empty_enrollments = enrollment_scope.
        where(id: enrollments_with_no_service.select(:id)).
        where(id: enrollments_with_no_cls.select(:id))

      empty_enrollments.find_each do |enrollment|
        enrollment.DateDeleted = Date.current
        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      enrollment_source.import(
        enrollment_batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:DateDeleted, :source_hash],
        },
      )
    end

    def enrollment_scope
      enrollment_source.
        joins(:project).
        merge(HmisCsvTwentyTwenty::Importer::Project.night_by_night).
        where(importer_log_id: @importer_log.id)
    end

    def enrollment_source
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def self.description
      'Delete enrollments in night-by-night projects that do not have any associated services or current living situations'
    end
  end
end
