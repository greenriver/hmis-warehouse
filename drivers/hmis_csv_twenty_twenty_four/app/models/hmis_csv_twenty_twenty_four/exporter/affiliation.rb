###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Affiliation
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def self.adjust_keys(row, _export)
      row.UserID = row.user&.id || 'op-system'
      row.ProjectID = row.project&.id || 'Unknown'
      row.ResProjectID = row.residential_project&.id || 'Unknown'
      row.AffiliationID = row.id

      row
    end

    def self.export_scope(project_scope:, export:, hmis_class:, **_)
      export_scope = case export.period_type
      when 3
        hmis_class.joins(:project).merge(project_scope)
      when 1
        hmis_class.joins(:project).merge(project_scope).
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.distinct.preload(:user)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyFour::Exporter::Affiliation,
        HmisCsvTwentyTwentyFour::Exporter::FakeData,
      ]
    end
  end
end
