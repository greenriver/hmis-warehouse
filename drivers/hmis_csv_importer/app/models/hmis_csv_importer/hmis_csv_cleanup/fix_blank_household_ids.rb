###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class FixBlankHouseholdIds < Base
    def cleanup!
      enrollment_batch = []

      enrollment_scope.find_each do |enrollment|
        # generate a consistent HouseholdID
        enrollment.HouseholdID = Digest::MD5.hexdigest([enrollment.EnrollmentID, enrollment.PersonalID, enrollment.ProjectID].join('__'))

        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      enrollment_source.import(
        enrollment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_source),
          columns: [:HouseholdID, :source_hash],
        },
      )
    end

    def enrollment_scope
      enrollment_source.
        where(importer_log_id: @importer_log.id).
        where(HouseholdID: [nil, ''])
    end

    def enrollment_source
      importable_file_class('Enrollment')
    end

    def self.description
      'Generate HouseholdIDs where not present'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::FixBlankHouseholdIds'],
        },
      }
    end
  end
end
