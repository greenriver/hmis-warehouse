module GrdaWarehouse::Export::HMISSixOneOne
  class ProjectCoc < GrdaWarehouse::Import::HMISSixOneOne::ProjectCoc
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
  end
end