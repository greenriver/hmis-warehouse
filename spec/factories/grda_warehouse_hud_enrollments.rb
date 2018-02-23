FactoryGirl.define do
  factory :hud_enrollment, class: 'GrdaWarehouse::Hud::Enrollment' do
    sequence(:ProjectID, 100)
    sequence(:ProjectEntryID, 1)
    sequence(:PersonalID, 10)
    sequence(:EntryDate) do |n|
      dates = [
        Date.today,
        8.weeks.ago,
        6.weeks.ago,
        4.weeks.ago,
        2.weeks.ago,
      ]
      dates[n%5].to_date
    end
  end
  factory :grda_warehouse_hud_enrollment, class: 'GrdaWarehouse::Hud::Enrollment' do
    # ProjectEntryID
    # PersonalID
    # ProjectID
    # EntryDate
    # HouseholdID
    # RelationshipToHoH
    # ResidencePrior
    # OtherResidencePrior
    # ResidencePriorLengthOfStay
    # DisablingCondition
    # EntryFromStreetESSH
    # DateToStreetESSH
    # ContinuouslyHomelessOneYear
    # TimesHomelessPastThreeYears
    MonthsHomelessPastThreeYears 4
    # MonthsHomelessThisTime
    # StatusDocumented
    # HousingStatus
    # DateOfEngagement
    # InPermanentHousing
    # ResidentialMoveInDate
    # DateOfPATHStatus
    # ClientEnrolledInPATH
    # ReasonNotEnrolled
    # WorstHousingSituation
    # PercentAMI
    # LastPermanentStreet
    # LastPermanentCity
    # LastPermanentState
    # LastPermanentZIP
    # AddressDataQuality
    # DateOfBCPStatus
    # FYSBYouth
    # ReasonNoServices
    # SexualOrientation
    # FormerWardChildWelfare
    # ChildWelfareYears
    # ChildWelfareMonths
    # FormerWardJuvenileJustice
    # JuvenileJusticeYears
    # JuvenileJusticeMonths
    # HouseholdDynamics
    # SexualOrientationGenderIDYouth
    # SexualOrientationGenderIDFam
    # HousingIssuesYouth
    # HousingIssuesFam
    # SchoolEducationalIssuesYouth
    # SchoolEducationalIssuesFam
    # UnemploymentYouth
    # UnemploymentFam
    # MentalHealthIssuesYouth
    # MentalHealthIssuesFam
    # HealthIssuesYouth
    # HealthIssuesFam
    # PhysicalDisabilityYouth
    # PhysicalDisabilityFam
    # MentalDisabilityYouth
    # MentalDisabilityFam
    # AbuseAndNeglectYouth
    # AbuseAndNeglectFam
    # AlcoholDrugAbuseYouth
    # AlcoholDrugAbuseFam
    # InsufficientIncome
    # ActiveMilitaryParent
    # IncarceratedParent
    # IncarceratedParentStatus
    # ReferralSource
    # CountOutreachReferralApproaches
    # ExchangeForSex
    # ExchangeForSexPastThreeMonths
    # CountOfExchangeForSex
    # AskedOrForcedToExchangeForSex
    # AskedOrForcedToExchangeForSexPastThreeMonths
    # WorkPlaceViolenceThreats
    # WorkplacePromiseDifference
    # CoercedToContinueWork
    # LaborExploitPastThreeMonths
    # HPScreeningScore
    # VAMCStation
    # DateCreated
    # DateUpdated
    # UserID
    # DateDeleted
    # ExportID
    # data_source_id
    # id
    # LOSUnderThreshold
    # PreviousStreetESSH
    # UrgentReferral
    # TimeToHousingLoss
    # ZeroIncome
    # AnnualPercentAMI
    # FinancialChange
    # HouseholdChange
    # EvictionHistory
    # SubsidyAtRisk
    # LiteralHomelessHistory
    # DisabledHoH
    # CriminalRecord
    # SexOffender
    # DependentUnder6
    # SingleParent
    # HH5Plus
    # IraqAfghanistan
    # FemVet
    # ThresholdScore
    # ERVisits
    # JailNights
    # HospitalNights
    # RunawayYouth
    # processed_has
  end
end
