###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Project
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
      row.UserID = row.user&.id || 'op-system'
      row.OrganizationID = row.organization&.id || 'Unknown'
      row.ProjectID = row.id

      row
    end

    def self.export_scope(project_scope:, export:, **_)
      export_scope = case export.period_type
      when 3
        project_scope
      when 1
        project_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.distinct.preload(:user, :organization)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Project::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::Project,
      ]
    end
  end
end
