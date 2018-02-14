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

    # Setup some joins so we can include deleted relationships when appropriate
    belongs_to :client_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Client.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments
    
    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments
        
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

    def self.export! enrollment_scope:, project_scope:, path:, export:
      case export.period_type
      when 3
        export_scope = enrollment_scope
      when 1
        export_scope = enrollment_scope.
          modified_within_range(range: (export.start_date..export.end_date))
      end
      
      export_to_path(
        export_scope: export_scope, 
        path: path, 
        export: export
      )
    end

  end
end