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

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :project_cocs

    def self.export! project_scope:, path:, export:
      if export.include_deleted
        project_coc_scope = joins(:project_with_deleted).merge(project_scope)
      else
        project_coc_scope = joins(:project).merge(project_scope)
      end
      export_to_path(export_scope: project_coc_scope, path: path, export: export)
    end

  end
end