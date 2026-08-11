###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Post-ingest import extension that delegates to HmisDataCleanup::FixIncorrectPersonalIdReferences.
module HmisCsvImporter::PostIngestCleanup
  class FixIncorrectPersonalIdReferences < Base
    def cleanup!
      HmisDataCleanup::FixIncorrectPersonalIdReferences.run!(
        data_source_id: importer_log.data_source_id,
        project_ids: project_ids,
        dry_run: false,
      )
    end

    def self.description
      'Align enrollment-related records\' PersonalID to their Enrollment.'
    end

    def self.enable
      {
        import_cleanups: {
          'Enrollment': ['HmisCsvImporter::PostIngestCleanup::FixIncorrectPersonalIdReferences'],
        },
      }
    end
  end
end
