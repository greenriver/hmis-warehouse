###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  class ForcePrioritizedPlacementStatus < Base
    def cleanup!
      assessment_batch = []
      assessment_scope.find_each do |assessment|
        assessment.PrioritizationStatus = 1
        assessment.set_source_hash
        assessment_batch << assessment
      end

      assessment_source.import(
        assessment_batch,
        on_duplicate_key_update: {
          conflict_target: conflict_target(assessment_source),
          columns: [:PrioritizationStatus, :source_hash],
        },
      )
    end

    def assessment_scope
      current_import = assessment_source.where(importer_log_id: @importer_log.id)
      current_import.where.not(PrioritizationStatus: 1).
        or(current_import.where(PrioritizationStatus: nil))
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
