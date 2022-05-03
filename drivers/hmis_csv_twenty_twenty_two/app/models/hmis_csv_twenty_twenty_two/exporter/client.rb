###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Enrollment
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def process(row)
      row.UserID ||= 'op-system'
      row.EnrollmentID = row.id
      row.PersonalID = row.client.id
      row.ProjectID = row.project&.id || 'Unknown'
    end

    def self.export_scope(client_scope:, export:)
      export_scope = case export.period_type
      when 3
        client_scope
      when 1
        client_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Client::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::Client,
      ]
    end
  end
end
