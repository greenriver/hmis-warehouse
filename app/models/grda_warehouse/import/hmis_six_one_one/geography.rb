module GrdaWarehouse::Import::HMISSixOneOne
  class Geography < GrdaWarehouse::Hud::Site
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :GeographyID,
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

    def self.file_name
      'Geography.csv'
    end

    # Currently this translates back to HMIS 5.1
    def self.translate_to_db_headers(row)
      row[:SiteID] = row.delete(:GeographyID)
      row[:Address] = row.delete(:Address1)
      return row
    end
  end
end