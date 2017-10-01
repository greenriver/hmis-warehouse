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

    def self.export! project_scope:, path:, export:
      export_to_path(
        export_scope: project_scope, 
        path: path, 
        export: export
      )
    end

  end
end