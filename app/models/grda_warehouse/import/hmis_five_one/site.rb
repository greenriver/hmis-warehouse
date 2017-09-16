module GrdaWarehouse::Import::HMISFiveOne
  class Site < GrdaWarehouse::Hud::Site
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :SiteID,
        :ProjectID,
        :CoCCode,
        :PrincipalSite,
        :Geocode,
        :Address,
        :City,
        :State,
        :ZIP,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :SiteID

    def self.file_name
      'Site.csv'
    end
  end
end