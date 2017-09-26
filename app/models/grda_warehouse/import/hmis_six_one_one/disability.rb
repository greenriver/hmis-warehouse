module GrdaWarehouse::Import::HMISSixOneOne
  class Disability < GrdaWarehouse::Hud::Disability
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :DisabilitiesID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :DisabilityType,
        :DisabilityResponse,
        :IndefiniteAndImpairs,
        :TCellCountAvailable,
        :TCellCount,
        :TCellSource,
        :ViralLoadAvailable,
        :ViralLoad,
        :ViralLoadSource,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :DisabilitiesID
    
    def self.date_provided_column 
      :InformationDate
    end

    def self.file_name
      'Disabilities.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
       # We've seen a bunch of integers come through as floats
      row[:TCellCount] = row[:TCellCount].to_i
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end
    
  end
end