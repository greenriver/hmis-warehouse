###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisCsvTwentyTwentyTwo::Exporter
  class Exit
    include ::HmisCsvTwentyTwentyTwo::Exporter::ExportConcern
    include ArelHelper

    def initialize(options)
      @options = options
    end

    def process(row)
      row.UserID = row.user&.id || 'op-system'
      # Pre-calculate and assign. After assignment the relations will be broken
      personal_id = personal_id(row, @options[:export])
      enrollment_id = enrollment_id(row, @options[:export])
      row.PersonalID = personal_id
      row.EnrollmentID = enrollment_id
      row.ExitID = row.id

      row
    end

    def self.export_scope(enrollment_scope:, export:, hmis_class:, **_)
      export_scope = case export.period_type
      when 3
        hmis_class.where(hmis_class.arel_table[:ExitDate].lteq(export.end_date))
      when 1
        hmis_class.modified_within_range(range: (export.start_date..export.end_date))
      end

      join_tables = if export.include_deleted || export.period_type == 1
        { enrollment_with_deleted: [:project_with_deleted, { client_with_deleted: :warehouse_client_source }] }
      else
        { enrollment: [:project, { client: :warehouse_client_source }] }
      end

      export_scope = export_scope.
        joins(join_tables).
        merge(enrollment_scope).
        preload([join_tables] + [:user])

      # Enforce only one exit per enrollment (we shouldn't need to do this, but sometimes we receive more than one exit for an enrollment and don't have cleanup on the import)
      mrex_t = Arel::Table.new(:most_recent_exits)
      join = ex_t.join(mrex_t).on(ex_t[:id].eq(mrex_t[:current_id]))
      export_scope = export_scope.where(
        id: GrdaWarehouse::Hud::Exit.
        with(
          most_recent_exits:
            export_scope.
              define_window(:exit_by_modification_date).partition_by(e_t[:id], order_by: { ex_t[:DateUpdated] => :desc }).
              select_window(:first_value, ex_t[:id], over: :exit_by_modification_date, as: :current_id),
        ).
          joins(join.join_sources),
      )

      note_involved_user_ids(scope: export_scope, export: export)
      export_scope.distinct
    end

    def self.transforms
      [
        HmisCsvTwentyTwentyTwo::Exporter::Exit::Overrides,
        HmisCsvTwentyTwentyTwo::Exporter::FakeData,
        HmisCsvTwentyTwentyTwo::Exporter::Exit,
      ]
    end
  end
end
