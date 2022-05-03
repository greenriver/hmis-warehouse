###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Enrollment
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
      row.UserID ||= 'op-system'
      row.EnrollmentID = row.id
      row.PersonalID = row.client.id
      row.ProjectID = row.project&.id || 'Unknown'

      row
    end

    def self.export_scope(enrollment_scope:, export:, **_)
      export_scope = case export.period_type
      when 3
        enrollment_scope
      when 1
        enrollment_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Enrollment::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::Enrollment,
      ]
    end
  end
end
