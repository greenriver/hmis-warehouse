module GrdaWarehouse::Export::HMISSixOneOne
  class HealthAndDv < GrdaWarehouse::Hud::HealthAndDv
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :HealthAndDVID,
        :EnrollmentID,
        :PersonalID,
        :InformationDate,
        :DomesticViolenceVictim,
        :WhenOccurred,
        :CurrentlyFleeing,
        :GeneralHealthStatus,
        :DentalHealthStatus,
        :MentalHealthStatus,
        :PregnancyStatus,
        :DueDate,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :HealthAndDVID
    
    def self.date_provided_column 
      :InformationDate
    end

    def self.file_name
      'HealthAndDV.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end
  end
end