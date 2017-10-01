module GrdaWarehouse::Export::HMISSixOneOne
  class Disability < GrdaWarehouse::Import::HMISSixOneOne::Disability

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
  end
end