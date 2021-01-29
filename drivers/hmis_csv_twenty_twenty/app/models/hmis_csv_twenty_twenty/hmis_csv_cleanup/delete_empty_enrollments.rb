###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class DeleteEmptyEnrollments < Base
    def cleanup!
      enrollment_batch = []

      es_with_no_service = enrollment_scope.
        merge(HmisCsvTwentyTwenty::Importer::Project.es.night_by_night).
        where.not(id: enrollment_scope.joins(:services).select(:id))

      es_with_no_service.find_each do |enrollment|
        enrollment.DateDeleted = Date.current
        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      so_with_no_cls = enrollment_scope.
        merge(HmisCsvTwentyTwenty::Importer::Project.so).
        where.not(id: enrollment_scope.joins(:current_living_situations).select(:id))

      so_with_no_cls.find_each do |enrollment|
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
        where(importer_log_id: @importer_log.id)
    end

    def enrollment_source
      HmisCsvTwentyTwenty::Importer::Enrollment
    end

    def self.description
      'Delete enrollments in ES or SO projects that do not have any associated services or current living situations'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvTwentyTwenty::HmisCsvCleanup::DeleteEmptyEnrollments'],
        },
      }
    end
  end
end
