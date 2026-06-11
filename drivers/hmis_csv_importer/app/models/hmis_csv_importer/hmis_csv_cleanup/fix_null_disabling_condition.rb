###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  class FixNullDisablingCondition < Base
    def cleanup!
      enrollment_batch = []

      enrollment_scope.find_each do |enrollment|
        enrollment.DisablingCondition = 99
        enrollment.set_source_hash
        enrollment_batch << enrollment
      end

      return if enrollment_batch.empty?

      enrollment_source.import(
        enrollment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(enrollment_source),
          columns: [:DisablingCondition, :source_hash],
        },
      )
    end

    def enrollment_scope
      enrollment_source.
        where(importer_log_id: @importer_log.id).
        where(DisablingCondition: nil)
    end

    def enrollment_source
      importable_file_class('Enrollment')
    end

    def self.description
      'Set null DisablingCondition on enrollments to 99 (Data not collected)'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::HmisCsvCleanup::FixNullDisablingCondition'],
        },
      }
    end
  end
end
