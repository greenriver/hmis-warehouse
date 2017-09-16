module GrdaWarehouse::Import::HMISFiveOne
  class Affiliation < GrdaWarehouse::Hud::Affiliation
    include ::Import::HMISFiveOne::Shared
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
    
    self.hud_key = :OrganizationID

    def self.file_name
      'Affiliation.csv'
    end
    
  end
end