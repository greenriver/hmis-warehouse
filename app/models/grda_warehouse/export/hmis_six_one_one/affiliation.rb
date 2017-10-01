module GrdaWarehouse::Export::HMISSixOneOne
  class Affiliation < GrdaWarehouse::Import::HMISSixOneOne::Affiliation
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :AffiliationID,
        :ProjectID,
        :ResProjectID,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :AffiliationID

    def self.export! project_scope:, path:, export:
      affiliation_scope = joins(:project).merge(project_scope)
      export_to_path(export_scope: affiliation_scope, path: path, export: export)
    end

  end
end