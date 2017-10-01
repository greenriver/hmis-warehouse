module GrdaWarehouse::Export::HMISSixOneOne
  class Service < GrdaWarehouse::Import::HMISSixOneOne::Service
    setup_hud_column_access( 
      [
        :ServicesID,
        :EnrollmentID,
        :PersonalID,
        :DateProvided,
        :RecordType,
        :TypeProvided,
        :OtherTypeProvided,
        :SubTypeProvided,
        :FAAmount,
        :ReferralOutcome,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ServicesID
  end
end