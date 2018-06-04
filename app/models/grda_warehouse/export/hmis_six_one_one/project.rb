module GrdaWarehouse::Export::HMISSixOneOne
  class Project < GrdaWarehouse::Import::HMISSixOneOne::Project
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( 
      [
        :ProjectID,
        :OrganizationID,
        :ProjectName,
        :ProjectCommonName,
        :OperatingStartDate,
        :OperatingEndDate,
        :ContinuumProject,
        :ProjectType,
        :ResidentialAffiliation,
        :TrackingMethod,
        :TargetPopulation,
        :VictimServicesProvider,
        :HousingType,
        :PITCount,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )

    self.hud_key = :ProjectID

    belongs_to :organization_with_delted, class_name: GrdaWarehouse::Hud::WithDeleted::Organization.name, primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id]

    def export! project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = project_scope
      when 1
        export_scope = project_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      
      export_to_path(
        export_scope: export_scope, 
        path: path, 
        export: export
      )
    end

  end
end