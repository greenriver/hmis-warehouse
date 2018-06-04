module GrdaWarehouse::Export::HMISSixOneOne
  class Geography < GrdaWarehouse::Import::HMISSixOneOne::Geography
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :SiteID,
        :ProjectID,
        :CoCCode,
        :InformationDate,
        :Geocode,
        :GeographyType,
        :Address,
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

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, primary_key: [:ProjectID, :data_source_id], foreign_key: [:ProjectID, :data_source_id], inverse_of: :sites

    # Replace SiteID with GeographyID
    def clean_headers(headers)
      headers.map do |k|
        if k == :SiteID
          :GeographyID
        elsif k == :Address
          :Address1
        else
          k
        end
      end
    end

  end
end