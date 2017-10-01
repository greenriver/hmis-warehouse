module GrdaWarehouse::Export::HMISSixOneOne
  class HealthAndDv < GrdaWarehouse::Import::HMISSixOneOne::HealthAndDv
    include ::Export::HMISSixOneOne::Shared
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
  end
end