module GrdaWarehouse::Import::HMISSixOneOne
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    include ::Import::HMISSixOneOne::Shared
    include TsqlImport
    
    setup_hud_column_access( 
      [
        :EnrollmentID,
        :PersonalID,
        :ProjectID,
        :EntryDate,
        :HouseholdID,
        :RelationshipToHoH,
        :LivingSituation,
        :LengthOfStay,
        :LOSUnderThreshold,
        :PreviousStreetESSH,
        :DateToStreetESSH,
        :TimesHomelessPastThreeYears,
        :MonthsHomelessPastThreeYears,
        :DisablingCondition,
        :DateOfEngagement,
        :MoveInDate,
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
        :EligibleForRHY,
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

    def self.file_name
      'Enrollment.csv'
    end

    def self.unique_constraint
      [self.hud_key, :data_source_id, :PersonalID]
    end

    def self.involved_enrollments(projects:, range:, data_source_id:)
      ids = []
      projects.each do |project|
        ids += self.joins(:project).
          open_during_range(range).
          where(Project: {ProjectID: project.ProjectID}, data_source_id: data_source_id).
          pluck(:id)
      end
      ids
    end

    # Currently this translates back to HMIS 5.1
    # and does other data cleanup as necessary
    def self.translate_to_db_headers(row)
      row[:ProjectEntryID] = row.delete(:EnrollmentID)
      row[:ResidencePrior] = row.delete(:LivingSituation)
      row[:ResidencePriorLengthOfStay] = row.delete(:LengthOfStay)
      row[:ResidentialMoveInDate] = row.delete(:MoveInDate)
      row[:FYSBYouth] = row.delete(:EligibleForRHY)
      return row
    end

    def self.should_log?
      true
    end

    def self.to_log
      @to_log ||= {
        hud_key: self.hud_key,
        personal_id: :PersonalID,
        effective_date: :EntryDate,
        data_source_id: :data_source_id,
      }
    end
  end
end