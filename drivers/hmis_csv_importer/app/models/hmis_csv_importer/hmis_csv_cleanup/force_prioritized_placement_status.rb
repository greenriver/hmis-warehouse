###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvImporter::HmisCsvCleanup
  class ForcePrioritizedPlacementStatus < Base
    def cleanup!
      assessment_scope.update_all(PrioritizationStatus: 1)
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
