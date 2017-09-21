module GrdaWarehouse::Import::HMISFiveOne
  class EnrollmentCoc < GrdaWarehouse::Hud::EnrollmentCoc
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :EnrollmentCoCID,
        :ProjectEntryID,
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
  end
end