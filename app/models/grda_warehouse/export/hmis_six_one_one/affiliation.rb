module GrdaWarehouse::Export::HMISSixOneOne
  class Affiliation < GrdaWarehouse::Import::HMISSixOneOne::Affiliation
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
  end
end