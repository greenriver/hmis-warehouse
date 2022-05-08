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
      row = self.class.adjust_keys(row, @options[:export])

      row
    end

    def self.adjust_keys(row, export)
      row.UserID = row.user&.id || 'op-system'
      # Pre-calculate and assign. After assignment the relations will be broken
      personal_id = personal_id(row, export)
      project_id = project_id(row, export)
      enrollment_id = enrollment_id(row, export)
      row.PersonalID = personal_id
      row.ProjectID = project_id
      row.EnrollmentID = enrollment_id
      row.EnrollmentCoCID = row.id

      row
    end

    def self.export_scope(enrollment_scope:, export:, hmis_class:, coc_codes:, **_)
      join_tables = if export.include_deleted || export.period_type == 1
        { enrollment_with_deleted: [{ client_with_deleted: :warehouse_client_source, project_with_deleted: :project_cocs_with_deleted }] }
      else
        { enrollment: [{ client: :warehouse_client_source, project: :project_cocs }] }
      end
      export_scope = hmis_class.joins(join_tables).preload([join_tables] + [:user])

      export_scope = case export.period_type
      when 3
        export_scope.merge(enrollment_scope).
          where(hmis_class.arel_table[:InformationDate].lteq(export.end_date))
      when 1
        export_scope.merge(enrollment_scope).
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope = export_scope.where(CoCCode: coc_codes) if coc_codes.present?

      export_scope.distinct
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
