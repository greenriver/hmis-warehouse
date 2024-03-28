###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyFour::Exporter
  class Enrollment
    include ::HmisCsvTwentyTwentyFour::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def self.adjust_keys(row, export)
      row.UserID = row.user&.id || 'op-system'

      # Pre-calculate and assign. After assignment the relations will be broken
      personal_id = if export.include_deleted || export.period_type == 1
        row&.client_with_deleted&.warehouse_client_source&.destination_id
      else
        row&.client&.warehouse_client_source&.destination_id
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
      # Limit to the chosen CoC codes if any are specified
      # Also include any blank records since enrollment.EnrollmentCoC isn't always set correctly
      filter = export.filter
      export_scope = export_scope.where(EnrollmentCoC: filter.coc_codes + [nil]) if filter.coc_codes.any?

      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.distinct.preload(:user, :project, client: :warehouse_client_source)
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyFour::Exporter::Enrollment::Overrides,
        HmisCsvTwentyTwentyFour::Exporter::Enrollment,
        HmisCsvTwentyTwentyFour::Exporter::FakeData,
      ]
    end
  end
end
