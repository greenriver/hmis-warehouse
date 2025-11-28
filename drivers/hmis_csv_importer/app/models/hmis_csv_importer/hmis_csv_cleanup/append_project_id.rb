###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvImporter::HmisCsvCleanup
  class AppendProjectId < Base
    def cleanup!
      project_scope.find_in_batches do |project_batch|
        project_batch.each do |project|
          project.ProjectName = "#{project.ProjectName} (#{project.ProjectID})"
          project.set_source_hash
        end

        project_source.import(
          project_batch,
          on_duplicate_key_update: {
            conflict_target: conflict_target(project_source),
            columns: [:ProjectName, :source_hash],
          },
        )
      end
    end

    def project_scope
      project_source.
        where(importer_log_id: @importer_log.id)
    end

    def project_source
      importable_file_class('Project')
    end

    def self.description
      'Append the HMIS ProjectID to the ProjectName field'
    end

    def self.enable
      {
        import_cleanups: {
          'Project': ['HmisCsvImporter::HmisCsvCleanup::AppendProjectId'],
        },
      }
    end
  end
end
