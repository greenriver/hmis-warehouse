module GrdaWarehouse::Export::HMISSixOneOne
  class Affiliation < GrdaWarehouse::Hud::Affiliation
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
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

    def self.file_name
      'Affiliation.csv'
    end
    
  end
end