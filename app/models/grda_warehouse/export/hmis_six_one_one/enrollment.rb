module GrdaWarehouse::Export::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Import::HMISSixOneOne::Enrollment
    include ::Export::HMISSixOneOne::Shared
    setup_hud_column_access( 
      [
        :ProjectEntryID,
        :PersonalID,
        :ProjectID,
        :EntryDate,
        :HouseholdID,
        :RelationshipToHoH,
        :ResidencePrior,
        :ResidencePriorLengthOfStay,
        :LOSUnderThreshold,
        :PreviousStreetESSH,
        :DateToStreetESSH,
        :TimesHomelessPastThreeYears,
        :MonthsHomelessPastThreeYears,
        :DisablingCondition,
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
        :RunawayYouth,
        :SexualOrientation,
        :FormerWardChildWelfare,
        :ChildWelfareYears,
        :ChildWelfareMonths,
        :FormerWardJuvenileJustice,
        :JuvenileJusticeYears,
        :JuvenileJusticeMonths,
        :UnemploymentFam,
        :MentalHealthIssuesFam,
        :PhysicalDisabilityFam,
        :AlcoholDrugAbuseFam,
        :InsufficientIncome,
        :IncarceratedParent,
        :ReferralSource,
        :CountOutreachReferralApproaches,
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
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID,        
      ]
    )
    
    self.hud_key = :ProjectEntryID

    # Replace 5.1 versions with 6.11
    # ProjectEntryID with EnrollmentID etc.
    def self.clean_headers(headers)
      headers.map do |k|
        case k
        when :ProjectEntryID
          :EnrollmentID
        when :ResidencePrior
          :LivingSituation
        when :ResidencePriorLengthOfStay
          :LengthOfStay
        when :ResidentialMoveInDate
          :MoveInDate
        when :FYSBYouth
          :EligibleForRHY
        else
          k
        end
      end
    end

    def self.export! enrollment_scope:, project_scope, path:, export:
      # include any enrollment within the original scope, plus
      # any modified during the range, regardless of when it was
      # open
      enrollment_scope = enrollment_scope
      export_to_path(
        export_scope: enrollment_scope, 
        path: path, 
        export: export
      )
    end
  end
end