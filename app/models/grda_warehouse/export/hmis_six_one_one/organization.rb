module GrdaWarehouse::Export::HMISSixOneOne
  class Organization < GrdaWarehouse::Import::HMISSixOneOne::Organization
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :OrganizationID,
        :OrganizationName,
        :OrganizationCommonName,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :OrganizationID

    def self.export! project_scope:, path:, export:
      organization_scope = joins(:projects).merge(project_scope)
      export_to_path(export_scope: organization_scope, path: path, export: export)
    end
  end
end