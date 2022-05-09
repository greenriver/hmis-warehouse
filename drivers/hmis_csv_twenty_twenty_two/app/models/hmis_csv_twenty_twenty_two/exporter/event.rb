###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Event
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
      enrollment_id = enrollment_id(row, export)
      row.PersonalID = personal_id
      row.EnrollmentID = enrollment_id
      row.EventID = row.id

      row
    end

    def self.export_scope(enrollment_scope:, export:, hmis_class:, **_)
      join_tables = enrollment_related_join_tables(export)
      export_scope = hmis_class.joins(join_tables).preload([join_tables] + [:user])

      export_scope = case export.period_type
      when 3
        export_scope.merge(enrollment_scope).
          where(hmis_class.arel_table[:EventDate].lteq(export.end_date))
      when 1
        export_scope.merge(enrollment_scope).
          modified_within_range(range: (export.start_date..export.end_date))
      end
      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.distinct
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Event,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
      ]
    end
  end
end
