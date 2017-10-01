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
      # Also include any projects created, modified, or deleted during the 
      # report range

      # Note:
      # union_scope = GrdaWarehouse::Hud::Project.from(arel_table.create_table_alias(project_scope.union(changed_scope), table_name))
      # SELECT "Project".* FROM ( SELECT "Project".* FROM "Project" WHERE "Project"."DateDeleted" IS NULL AND "Project"."id" = $1 UNION SELECT "Project".* FROM "Project" WHERE "Project"."DateDeleted" IS NULL AND "Project"."id" = $2 ) "Project" WHERE "Project"."DateDeleted" IS NULL

      changed_scope = modified_within_range(range: (export.start_date..export.end_date), include_deleted: export.include_deleted)
      union_scope = from(
        arel_table.create_table_alias(
          project_scope.union(changed_scope),
          table_name
        )
      )
      export_to_path(
        export_scope: union_scope, 
        path: path, 
        export: export
      )
    end

  end
end