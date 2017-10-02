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

    def self.export! project_scope:, path:, export:
      if export.include_deleted
        project_scope = project_scope.joins(:organization_with_delted)
      else
        project_scope = project_scope.joins(:organization)
      end
      export_to_path(
        export_scope: project_scope, 
        path: path, 
        export: export
      )
    end

  end
end