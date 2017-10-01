module GrdaWarehouse::Export::HMISSixOneOne
  class ProjectCoc < GrdaWarehouse::Import::HMISSixOneOne::ProjectCoc
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :ProjectCoCID,
        :ProjectID,
        :CoCCode,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ProjectCoCID

    def self.export! project_scope:, path:, export:
      project_coc_scope = joins(:project).merge(project_scope)
      export_to_path(export_scope: project_coc_scope, path: path, export: export)
    end
  end
end