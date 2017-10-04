module GrdaWarehouse::Import::HMISSixOneOne
  class Organization < GrdaWarehouse::Hud::Organization
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
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

    def self.file_name
      'Organization.csv'
    end
    
  end
end