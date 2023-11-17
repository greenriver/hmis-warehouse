###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForcePrioritizedPlacementStatus < Base
    def cleanup!
      assessment_batch = []

      assessment_scope.update(PrioritizationStatus: 1)

      assessment_scope.import(
        assessment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(assessment_scope),
          columns: [:PrioritizationStatus, :source_hash],
        },
      )
    end

    def assessment_scope
      assessment_source.
        where(importer_log_id: @importer_log.id).
        where.not(PrioritizationStatus: 1).
        or(assessment_source.where(PrioritizationStatus: nil))
    end

    def assessment_source
      importable_file_class('Assessment')
    end

    def self.description
      'Set Prioritization Status to "Placed on prioritization list"'
    end

    def self.enable
      {
        import_cleanups: {
          'Assessment': ['HmisCsvImporter::HmisCsvCleanup::ForcePrioritizedPlacementStatus'],
        },
      }
    end
  end
end
