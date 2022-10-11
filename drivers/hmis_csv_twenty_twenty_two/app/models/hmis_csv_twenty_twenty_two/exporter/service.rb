###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Service
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern

    def initialize(options)
      @options = options
    end

    def process(row)
      row = assign_export_id(row)
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
      row.ServicesID = row.id

      row
    end

    def self.export_scope(enrollment_scope:, export:, hmis_class:, temp_class:, **_)
      join_tables = enrollment_related_join_tables(export)
      intermediate_scope = hmis_class.joins(join_tables)

      intermediate_scope = case export.period_type
      when 3
        intermediate_scope.merge(enrollment_scope).
          where(hmis_class.arel_table[:DateProvided].lteq(export.end_date))
      when 1
        intermediate_scope.merge(enrollment_scope).
          modified_within_range(range: (export.start_date..export.end_date))
      end

      ids = intermediate_scope.distinct.pluck(:id)
      temp_class.import([:source_id], ids.map { |id| [id] }, batch_size: 50_000)
      tmp_export_table = temp_class.arel_table
      export_scope = hmis_class.joins(hmis_class.arel_table.join(tmp_export_table).on(hmis_class.arel_table[:id].eq(tmp_export_table[:source_id])).join_sources)

      note_involved_user_ids(scope: export_scope, export: export)

      export_scope.preload([join_tables] + [:user]).distinct
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Service::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::Service,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
      ]
    end
  end
end
