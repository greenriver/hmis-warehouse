module GrdaWarehouse::Export::HMISSixOneOne
  class Exit < GrdaWarehouse::Import::HMISSixOneOne::Exit
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( GrdaWarehouse::Hud::Exit.hud_csv_headers(version: '6.11') )

    self.hud_key = :ExitID

     # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id]


    def export! enrollment_scope:, project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = self.class.where(id: enrollment_scope.select(ex_t[:id]))
        export_scope = export_scope.where(self.class.arel_table[:ExitDate].lteq(export.end_date))
      when 1
        export_scope = self.class.where(id: enrollment_scope.select(ex_t[:id])).
          modified_within_range(range: (export.start_date..export.end_date))
      end

      if export.include_deleted || export.period_type == 1
        join_tables = {enrollment_with_deleted: [{client_with_deleted: :warehouse_client_source}]}
      else
        join_tables = {enrollment: [:project, {client: :warehouse_client_source}]}
      end

      if columns_to_pluck.include?(:ProjectID)
        if export.include_deleted || export.period_type == 1
          join_tables[:enrollment_with_deleted] << :project_with_deleted
        else
          join_tables[:enrollment] << :project
        end
      end
      export_scope = export_scope.joins(join_tables)

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export
      )
    end
  end
end