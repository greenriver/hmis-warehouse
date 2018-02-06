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

    has_many :projects_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:OrganizationID, :data_source_id], foreign_key: [:OrganizationID, :data_source_id], inverse_of: :organization

    def self.export! project_scope:, path:, export:
      
      if export.include_deleted
        organization_scope = joins(:projects_with_deleted).merge(project_scope)
      else
        organization_scope = joins(:projects).merge(project_scope)
      end
      export_to_path(
        export_scope: organization_scope,
        path: path,
        export: export
      )
    end

  end
end