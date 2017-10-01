module GrdaWarehouse::Export::HMISSixOneOne
  class Funder < GrdaWarehouse::Import::HMISSixOneOne::Funder
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
  end
end