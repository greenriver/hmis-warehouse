module GrdaWarehouse::Export::HMISSixOneOne
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    include ::Export::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :EnrollmentCoCID,
        :EnrollmentID,
        :HouseholdID,
        :ProjectID,
        :PersonalID,
        :InformationDate,
        :CoCCode,
        :DataCollectionStage,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :EnrollmentCoCID
    
    def self.date_provided_column 
      :InformationDate
    end

    def self.file_name
      'EnrollmentCoC.csv'
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end
  end
end