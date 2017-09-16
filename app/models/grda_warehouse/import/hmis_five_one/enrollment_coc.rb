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

    def self.file_name
      'EnrollmentCoC.csv'
    end
    
    # Load up HUD Key and DateUpdated for existing in same data source
    # Loop over incoming, see if the key is there with a newer DateUpdated
    # Update if newer, create if it isn't there, otherwise do nothing
    def self.import!(data_source_id, file_path:)
      stats = {
        lines_added: 0, 
        lines_updated: 0, 
      }
      to_add = []
      
    end
  end
end