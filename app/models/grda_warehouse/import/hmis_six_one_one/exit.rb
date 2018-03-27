module GrdaWarehouse::Import::HMISSixOneOne
  class Exit < GrdaWarehouse::Hud::Exit
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
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

    def self.file_name
      'Exit.csv'
    end

    def self.involved_exits(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        # Remove any exits that fall within the export range
        ids += self.joins(:project, :enrollment).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          where(ExitDate: range.range).
          pluck(:id)
      end
      ids
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      return row
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :ExitDate,
        data_source_id: :data_source_id,
      }
    end
  end
end