module GrdaWarehouse::Export::HMISSixOneOne
  class Organization < GrdaWarehouse::Import::HMISSixOneOne::Organization
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
  end
end