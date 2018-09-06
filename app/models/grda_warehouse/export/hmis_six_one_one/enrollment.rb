module GrdaWarehouse::Export::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Import::HMISSixOneOne::Enrollment
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( GrdaWarehouse::Hud::Enrollment.hud_csv_headers(version: '6.11') )

    self.hud_key = :EnrollmentID

    # Setup some joins so we can include deleted relationships when appropriate
    belongs_to :client_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Client.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments

    def export! enrollment_scope:, project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = enrollment_scope
      when 1
        export_scope = enrollment_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end

      export_to_path(
        export_scope: export_scope,
        path: path,
        export: export
      )
    end

    # HouseholdID and RelationshipToHoH are required, but often not provided, send some sane defaults
    # Also unique the HouseholdID to a data source
    def apply_overrides row, data_source_id:
      if row[:HouseholdID].blank?
        row[:HouseholdID] = "p_#{client_export_id(row[:EnrollmentID])}"
      else
        row[:HouseholdID] = "#{data_source_id}_#{row[:ProjectID]}_#{(row[:HouseholdID])}"
      end
      row[:RelationshipToHoH] = 1 if row[:RelationshipToHoH].blank?
      return row
    end

  end
end