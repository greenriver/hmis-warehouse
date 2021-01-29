###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwenty::HmisCsvCleanup
  class PrependProjectId < Base
    def cleanup!
      project_batch = []

      project_scope.find_each do |project|
        project.ProjectName = "(#{project.ProjectID}) #{project.ProjectName}"
        project.set_source_hash
        project_batch << project
      end

      project_source.import(
        project_batch,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: [:ProjectName, :source_hash],
        },
      )
    end

    def project_scope
      project_source.
        where(importer_log_id: @importer_log.id)
    end

    def project_source
      HmisCsvTwentyTwenty::Importer::Project
    end

    def self.description
      'Prepend the HMIS ProjectID to the ProjectName field'
    end

    def self.enable
      {
        import_cleanups: {
          'Project': ['HmisCsvTwentyTwenty::HmisCsvCleanup::PrependProjectId'],
        },
      }
    end
  end
end
