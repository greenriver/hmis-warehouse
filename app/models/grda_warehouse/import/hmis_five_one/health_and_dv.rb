module GrdaWarehouse::Import::HMISFiveOne
  class HealthAndDv < GrdaWarehouse::Hud::HealthAndDv
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :HealthAndDVID,
        :ProjectEntryID,
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

    def self.file_name
      'HealthAndDV.csv'
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