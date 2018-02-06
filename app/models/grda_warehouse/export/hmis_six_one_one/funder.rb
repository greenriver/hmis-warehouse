module GrdaWarehouse::Export::HMISSixOneOne
  class Funder < GrdaWarehouse::Import::HMISSixOneOne::Funder
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :FunderID,
        :ProjectID,
        :Funder,
        :GrantID,
        :StartDate,
        :EndDate,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :FunderID

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :funders

    def self.export! project_scope:, path:, export:
      if export.include_deleted
        funder_scope = joins(:project_with_deleted).merge(project_scope)
      else
        funder_scope = joins(:project).merge(project_scope)
      end
      export_to_path(
        export_scope: funder_scope, 
        path: path, 
        export: export
      )
    end
  end
end