###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class EnrollmentCoc
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
      row.UserID = row.user&.id || 'op-system'
      # Pre-calculate and assign. After assignment the relations will be broken
      personal_id = personal_id(row, @options[:export])
      project_id = project_id(row, @options[:export])
      enrollment_id = enrollment_id(row, @options[:export])
      row.PersonalID = personal_id
      row.ProjectID = project_id
      row.EnrollmentID = enrollment_id
      row.EnrollmentCoCID = row.id

      row
    end

    def self.export_scope(enrollment_scope:, export:, hmis_class:, **_)
      export_scope = case export.period_type
      when 3
        hmis_class.where(enrollment_exists_for_model(enrollment_scope, hmis_class)).
          where(hmis_class.arel_table[:InformationDate].lteq(export.end_date))
      when 1
        hmis_class.where(enrollment_exists_for_model(enrollment_scope, hmis_class)).
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      join_tables = if export.include_deleted || export.period_type == 1
        { enrollment_with_deleted: [{ client_with_deleted: :warehouse_client_source, project_with_deleted: :project_cocs_with_deleted }] }
      else
        { enrollment: [{ client: :warehouse_client_source, project: :project_cocs }] }
      end

      export_scope = export_scope.joins(join_tables)

      export_scope
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::EnrollmentCoc,
      ]
    end
  end
end
