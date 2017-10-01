module GrdaWarehouse::Export::HMISSixOneOne
  class EnrollmentCoc < GrdaWarehouse::Import::HMISSixOneOne::EnrollmentCoc
    include ::Export::HMISSixOneOne::Shared
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
  end
end