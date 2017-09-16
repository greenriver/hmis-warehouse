module GrdaWarehouse::Import::HMISFiveOne
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include ::Import::HMISFiveOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :ProjectEntryID,
        :PersonalID,
        :ProjectID,
        :EntryDate,
        :HouseholdID,
        :RelationshipToHoH,
        :ResidencePrior,
        :OtherResidencePrior,
        :ResidencePriorLengthOfStay,
        :LOSUnderThreshold,
        :PreviousStreetESSH,
        :DateToStreetESSH,
        :TimesHomelessPastThreeYears,
        :MonthsHomelessPastThreeYears,
        :DisablingCondition,
        :HousingStatus,
        :DateOfEngagement,
        :ResidentialMoveInDate,
        :DateOfPATHStatus,
        :ClientEnrolledInPATH,
        :ReasonNotEnrolled,
        :WorstHousingSituation,
        :PercentAMI,
        :LastPermanentStreet,
        :LastPermanentCity,
        :LastPermanentState,
        :LastPermanentZIP,
        :AddressDataQuality,
        :DateOfBCPStatus,
        :FYSBYouth,
        :ReasonNoServices,
        :SexualOrientation,
        :FormerWardChildWelfare,
        :ChildWelfareYears,
        :ChildWelfareMonths,
        :FormerWardJuvenileJustice,
        :JuvenileJusticeYears,
        :JuvenileJusticeMonths,
        :HouseholdDynamics,
        :SexualOrientationGenderIDYouth,
        :SexualOrientationGenderIDFam,
        :HousingIssuesYouth,
        :HousingIssuesFam,
        :SchoolEducationalIssuesYouth,
        :SchoolEducationalIssuesFam,
        :UnemploymentYouth,
        :UnemploymentFam,
        :MentalHealthIssuesYouth,
        :MentalHealthIssuesFam,
        :HealthIssuesYouth,
        :HealthIssuesFam,
        :PhysicalDisabilityYouth,
        :PhysicalDisabilityFam,
        :MentalDisabilityYouth,
        :MentalDisabilityFam,
        :AbuseAndNeglectYouth,
        :AbuseAndNeglectFam,
        :AlcoholDrugAbuseYouth,
        :AlcoholDrugAbuseFam,
        :InsufficientIncome,
        :ActiveMilitaryParent,
        :IncarceratedParent,
        :IncarceratedParentStatus,
        :ReferralSource,
        :CountOutreachReferralApproaches,
        :ExchangeForSex,
        :ExchangeForSexPastThreeMonths,
        :CountOfExchangeForSex,
        :AskedOrForcedToExchangeForSex,
        :AskedOrForcedToExchangeForSexPastThreeMonths,
        :WorkPlaceViolenceThreats,
        :WorkplacePromiseDifference,
        :CoercedToContinueWork,
        :LaborExploitPastThreeMonths,
        :UrgentReferral,
        :TimeToHousingLoss,
        :ZeroIncome,
        :AnnualPercentAMI,
        :FinancialChange,
        :HouseholdChange,
        :EvictionHistory,
        :SubsidyAtRisk,
        :LiteralHomelessHistory,
        :DisabledHoH,
        :CriminalRecord,
        :SexOffender,
        :DependentUnder6,
        :SingleParent,
        :HH5Plus,
        :IraqAfghanistan,
        :FemVet,
        :HPScreeningScore,
        :ThresholdScore,
        :VAMCStation,
        :ERVisits,
        :JailNights,
        :HospitalNights,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,
      ]
    )
    
    self.hud_key = :ProjectEntryID

    def self.file_name
      'Enrollment.csv'
    end

    def involved_enrollments(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        ids += self.joins(:project).
          open_during_range(range).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          pluck(:id)
      end
      ids
    end  
  end
end