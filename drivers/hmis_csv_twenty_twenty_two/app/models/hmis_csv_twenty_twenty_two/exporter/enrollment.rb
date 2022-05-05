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
      row.UserID = row.user&.id || 'op-system'

      # Pre-calculate and assign. After assignment the relations will be broken
      export = @options[:export]
      personal_id = if export.include_deleted || export.period_type == 1
        row&.client_with_deleted&.id
      else
        row&.client&.id
      end
      project_id = if export.include_deleted || export.period_type == 1
        row&.project_with_deleted&.id
      else
        row&.project&.id
      end
      row.PersonalID = personal_id
      row.ProjectID = project_id
      row.EnrollmentID = row.id

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

      export_scope.distinct.preload(:user, :project, :client)
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
