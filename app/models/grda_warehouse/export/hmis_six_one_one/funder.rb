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

    def self.export! project_scope:, path:, export:
      funder_scope = joins(:project).merge(project_scope)
      export_to_path(export_scope: funder_scope, path: path, export: export)
    end
  end
end