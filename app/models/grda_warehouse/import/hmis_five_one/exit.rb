module GrdaWarehouse::Import::HMISFiveOne
  class Exit < GrdaWarehouse::Hud::Exit
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
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
        :ConnectionWithSOAR,
        :WrittenAftercarePlan,
        :AssistanceMainstreamBenefits,
        :PermanentHousingPlacement,
        :TemporaryShelterPlacement,
        :ExitCounseling,
        :FurtherFollowUpServices,
        :ScheduledFollowUpContacts,
        :ResourcePackage,
        :OtherAftercarePlanOrAction,
        :ProjectCompletionStatus,
        :EarlyExitReason,
        :FamilyReunificationAchieved,
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

    def involved_exits(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        ids += self.joins(:project, :enrollment).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
          pluck(:id)
      end
      ids
    end
  end
end