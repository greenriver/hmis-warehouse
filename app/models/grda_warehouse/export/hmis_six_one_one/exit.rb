module GrdaWarehouse::Export::HMISSixOneOne
  class Exit < GrdaWarehouse::Import::HMISSixOneOne::Exit
    include ::Export::HMISSixOneOne::Shared

    setup_hud_column_access( 
      [
        :ExitID,
        :ProjectEntryID,
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

     # Setup an association to enrollment that allows us to pull the records even if the 
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Enrollment.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id]

    # Replace 5.1 versions with 6.11
    # ProjectEntryID with EnrollmentID etc.
    def self.clean_headers(headers)
      headers.map do |k|
        case k
        when :ProjectEntryID
          :EnrollmentID
        else
          k
        end
      end
    end

    def self.includes_union?
      true
    end

  end
end