module GrdaWarehouse::Export::HMISSixOneOne
  class Geography < GrdaWarehouse::Import::HMISSixOneOne::Geography
    setup_hud_column_access( 
      [
        :SiteID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :Geocode,
        :GeographyType,
        :Address1,
        :Address2,
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

    # Replace SiteID with GeographyID
    def self.clean_headers(headers)
      headers.map do |k|
        if k == :SiteID
          :GeographyID
        else
          k
        end
      end
    end


  end
end