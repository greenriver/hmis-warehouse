module GrdaWarehouse::Export::HMISSixOneOne
  class Exit < GrdaWarehouse::Import::HMISSixOneOne::Exit
    include ::Export::HMISSixOneOne::Shared
    
    setup_hud_column_access( 
      [
        :ExitID,
        :EnrollmentID,
        :PersonalID,
        :ExitDate,
        :Destination,
        :OtherDestination,
        :AssessmentDisposition,
        :OtherDisposition,
        :HousingAssessment,
        :SubsidyInformation,
        :ProjectCompletionStatus,
        :EarlyExitReason,
        :ExchangeForSex,
        :ExchangeForSexPastThreeMonths,
        :CountOfExchangeForSex,
        :AskedOrForcedToExchangeForSex,
        :AskedOrForcedToExchangeForSexPastThreeMonths,
        :WorkPlaceViolenceThreats,
        :WorkplacePromiseDifference,
        :CoercedToContinueWork,
        :LaborExploitPastThreeMonths,
        :CounselingReceived,
        :IndividualCounseling,
        :FamilyCounseling,
        :GroupCounseling,
        :SessionCountAtExit,
        :PostExitCounselingPlan,
        :SessionsInPlan,
        :DestinationSafeClient,
        :DestinationSafeWorker,
        :PosAdultConnections,
        :PosPeerConnections,
        :PosCommunityConnections,
        :AftercareDate,
        :AftercareProvided,
        :EmailSocialMedia,
        :Telephone,
        :InPersonIndividual,
        :InPersonGroup,
        :CMExitReason,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ExitID
  end
end