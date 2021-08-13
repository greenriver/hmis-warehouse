###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HMIS::Structure::Enrollment
  extend ActiveSupport::Concern
  include ::HMIS::Structure::Base

  included do
    self.hud_key = :EnrollmentID
    self.conflict_target = [:data_source_id, connection.quote_column_name(:EnrollmentID), connection.quote_column_name(:PersonalID)]
    self.additional_upsert_columns = [:processed_as]
    acts_as_paranoid(column: :DateDeleted)
  end

  module ClassMethods
    def hmis_configuration(version: nil)
      case version
      when '6.11', '6.12'
        {
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EntryDate: {
            type: :date,
            null: false,
          },
          HouseholdID: {
            type: :string,
            limit: 32,
            null: false,
          },
          RelationshipToHoH: {
            type: :integer,
          },
          LivingSituation: {
            type: :integer,
          },
          LengthOfStay: {
            type: :integer,
          },
          LOSUnderThreshold: {
            type: :integer,
          },
          PreviousStreetESSH: {
            type: :integer,
          },
          DateToStreetESSH: {
            type: :date,
          },
          TimesHomelessPastThreeYears: {
            type: :integer,
          },
          MonthsHomelessPastThreeYears: {
            type: :integer,
          },
          DisablingCondition: {
            type: :integer,
          },
          DateOfEngagement: {
            type: :date,
          },
          MoveInDate: {
            type: :date,
          },
          DateOfPATHStatus: {
            type: :date,
          },
          ClientEnrolledInPATH: {
            type: :integer,
          },
          ReasonNotEnrolled: {
            type: :integer,
          },
          WorstHousingSituation: {
            type: :integer,
          },
          PercentAMI: {
            type: :integer,
          },
          LastPermanentStreet: {
            type: :string,
            limit: 100,
          },
          LastPermanentCity: {
            type: :string,
            limit: 50,
          },
          LastPermanentState: {
            type: :string,
            limit: 2,
          },
          LastPermanentZIP: {
            type: :string,
            limit: 5,
          },
          AddressDataQuality: {
            type: :integer,
          },
          DateOfBCPStatus: {
            type: :date,
          },
          EligibleForRHY: {
            type: :integer,
          },
          ReasonNoServices: {
            type: :integer,
          },
          RunawayYouth: {
            type: :integer,
          },
          SexualOrientation: {
            type: :integer,
          },
          FormerWardChildWelfare: {
            type: :integer,
          },
          ChildWelfareYears: {
            type: :integer,
          },
          ChildWelfareMonths: {
            type: :integer,
          },
          FormerWardJuvenileJustice: {
            type: :integer,
          },
          JuvenileJusticeYears: {
            type: :integer,
          },
          JuvenileJusticeMonths: {
            type: :integer,
          },
          UnemploymentFam: {
            type: :integer,
          },
          MentalHealthIssuesFam: {
            type: :integer,
          },
          PhysicalDisabilityFam: {
            type: :integer,
          },
          AlcoholDrugAbuseFam: {
            type: :integer,
          },
          InsufficientIncome: {
            type: :integer,
          },
          IncarceratedParent: {
            type: :integer,
          },
          ReferralSource: {
            type: :integer,
          },
          CountOutreachReferralApproaches: {
            type: :integer,
          },
          UrgentReferral: {
            type: :integer,
          },
          TimeToHousingLoss: {
            type: :integer,
          },
          ZeroIncome: {
            type: :integer,
          },
          AnnualPercentAMI: {
            type: :integer,
          },
          FinancialChange: {
            type: :integer,
          },
          HouseholdChange: {
            type: :integer,
          },
          EvictionHistory: {
            type: :integer,
          },
          SubsidyAtRisk: {
            type: :integer,
          },
          LiteralHomelessHistory: {
            type: :integer,
          },
          DisabledHoH: {
            type: :integer,
          },
          CriminalRecord: {
            type: :integer,
          },
          SexOffender: {
            type: :integer,
          },
          DependentUnder6: {
            type: :integer,
          },
          SingleParent: {
            type: :integer,
          },
          HH5Plus: {
            type: :integer,
          },
          IraqAfghanistan: {
            type: :integer,
          },
          FemVet: {
            type: :integer,
          },
          HPScreeningScore: {
            type: :integer,
          },
          ThresholdScore: {
            type: :integer,
          },
          VAMCStation: {
            type: :string,
            limit: 5,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      when '2020', nil
        {
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EntryDate: {
            type: :date,
            null: false,
          },
          HouseholdID: {
            type: :string,
            limit: 32,
            null: false,
          },
          RelationshipToHoH: {
            type: :integer,
          },
          LivingSituation: {
            type: :integer,
          },
          LengthOfStay: {
            type: :integer,
          },
          LOSUnderThreshold: {
            type: :integer,
          },
          PreviousStreetESSH: {
            type: :integer,
          },
          DateToStreetESSH: {
            type: :date,
          },
          TimesHomelessPastThreeYears: {
            type: :integer,
          },
          MonthsHomelessPastThreeYears: {
            type: :integer,
          },
          DisablingCondition: {
            type: :integer,
          },
          DateOfEngagement: {
            type: :date,
          },
          MoveInDate: {
            type: :date,
          },
          DateOfPATHStatus: {
            type: :date,
          },
          ClientEnrolledInPATH: {
            type: :integer,
          },
          ReasonNotEnrolled: {
            type: :integer,
          },
          WorstHousingSituation: {
            type: :integer,
          },
          PercentAMI: {
            type: :integer,
          },
          LastPermanentStreet: {
            type: :string,
            limit: 100,
          },
          LastPermanentCity: {
            type: :string,
            limit: 50,
          },
          LastPermanentState: {
            type: :string,
            limit: 2,
          },
          LastPermanentZIP: {
            type: :string,
            limit: 5,
          },
          AddressDataQuality: {
            type: :integer,
          },
          DateOfBCPStatus: {
            type: :date,
          },
          EligibleForRHY: {
            type: :integer,
          },
          ReasonNoServices: {
            type: :integer,
          },
          RunawayYouth: {
            type: :integer,
          },
          SexualOrientation: {
            type: :integer,
          },
          SexualOrientationOther: {
            type: :string,
            limit: 100,
          },
          FormerWardChildWelfare: {
            type: :integer,
          },
          ChildWelfareYears: {
            type: :integer,
          },
          ChildWelfareMonths: {
            type: :integer,
          },
          FormerWardJuvenileJustice: {
            type: :integer,
          },
          JuvenileJusticeYears: {
            type: :integer,
          },
          JuvenileJusticeMonths: {
            type: :integer,
          },
          UnemploymentFam: {
            type: :integer,
          },
          MentalHealthIssuesFam: {
            type: :integer,
          },
          PhysicalDisabilityFam: {
            type: :integer,
          },
          AlcoholDrugAbuseFam: {
            type: :integer,
          },
          InsufficientIncome: {
            type: :integer,
          },
          IncarceratedParent: {
            type: :integer,
          },
          ReferralSource: {
            type: :integer,
          },
          CountOutreachReferralApproaches: {
            type: :integer,
          },
          UrgentReferral: {
            type: :integer,
          },
          TimeToHousingLoss: {
            type: :integer,
          },
          ZeroIncome: {
            type: :integer,
          },
          AnnualPercentAMI: {
            type: :integer,
          },
          FinancialChange: {
            type: :integer,
          },
          HouseholdChange: {
            type: :integer,
          },
          EvictionHistory: {
            type: :integer,
          },
          SubsidyAtRisk: {
            type: :integer,
          },
          LiteralHomelessHistory: {
            type: :integer,
          },
          DisabledHoH: {
            type: :integer,
          },
          CriminalRecord: {
            type: :integer,
          },
          SexOffender: {
            type: :integer,
          },
          DependentUnder6: {
            type: :integer,
          },
          SingleParent: {
            type: :integer,
          },
          HH5Plus: {
            type: :integer,
          },
          IraqAfghanistan: {
            type: :integer,
          },
          FemVet: {
            type: :integer,
          },
          HPScreeningScore: {
            type: :integer,
          },
          ThresholdScore: {
            type: :integer,
          },
          VAMCStation: {
            type: :string,
            limit: 5,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      when '2022'
        {
          EnrollmentID: {
            type: :string,
            limit: 32,
            null: false,
          },
          PersonalID: {
            type: :string,
            limit: 32,
            null: false,
          },
          ProjectID: {
            type: :string,
            limit: 32,
            null: false,
          },
          EntryDate: {
            type: :date,
            null: false,
          },
          HouseholdID: {
            type: :string,
            limit: 32,
            null: false,
          },
          RelationshipToHoH: {
            type: :integer,
          },
          LivingSituation: {
            type: :integer,
          },
          LengthOfStay: {
            type: :integer,
          },
          LOSUnderThreshold: {
            type: :integer,
          },
          PreviousStreetESSH: {
            type: :integer,
          },
          DateToStreetESSH: {
            type: :date,
          },
          TimesHomelessPastThreeYears: {
            type: :integer,
          },
          MonthsHomelessPastThreeYears: {
            type: :integer,
          },
          DisablingCondition: {
            type: :integer,
          },
          DateOfEngagement: {
            type: :date,
          },
          MoveInDate: {
            type: :date,
          },
          DateOfPATHStatus: {
            type: :date,
          },
          ClientEnrolledInPATH: {
            type: :integer,
          },
          ReasonNotEnrolled: {
            type: :integer,
          },
          WorstHousingSituation: {
            type: :integer,
          },
          PercentAMI: {
            type: :integer,
          },
          LastPermanentStreet: {
            type: :string,
            limit: 100,
          },
          LastPermanentCity: {
            type: :string,
            limit: 50,
          },
          LastPermanentState: {
            type: :string,
            limit: 2,
          },
          LastPermanentZIP: {
            type: :string,
            limit: 5,
          },
          AddressDataQuality: {
            type: :integer,
          },
          ReferralSource: {
            type: :integer,
          },
          CountOutreachReferralApproaches: {
            type: :integer,
          },
          DateOfBCPStatus: {
            type: :date,
          },
          EligibleForRHY: {
            type: :integer,
          },
          ReasonNoServices: {
            type: :integer,
          },
          RunawayYouth: {
            type: :integer,
          },
          SexualOrientation: {
            type: :integer,
          },
          SexualOrientationOther: {
            type: :string,
            limit: 100,
          },
          FormerWardChildWelfare: {
            type: :integer,
          },
          ChildWelfareYears: {
            type: :integer,
          },
          ChildWelfareMonths: {
            type: :integer,
          },
          FormerWardJuvenileJustice: {
            type: :integer,
          },
          JuvenileJusticeYears: {
            type: :integer,
          },
          JuvenileJusticeMonths: {
            type: :integer,
          },
          UnemploymentFam: {
            type: :integer,
          },
          MentalHealthDisorderFam: {
            type: :integer,
          },
          PhysicalDisabilityFam: {
            type: :integer,
          },
          AlcoholDrugUseDisorderFam: {
            type: :integer,
          },
          InsufficientIncome: {
            type: :integer,
          },
          IncarceratedParent: {
            type: :integer,
          },
          VAMCStation: {
            type: :string,
            limit: 5,
          },
          TargetScreenReqd: {
            type: :integer,
          },
          UrgentReferral: {
            type: :integer,
          },
          TimeToHousingLoss: {
            type: :integer,
          },
          AnnualPercentAMI: {
            type: :integer,
          },
          LiteralHomelessHistory: {
            type: :integer,
          },
          ClientLeaseholder: {
            type: :integer,
          },
          HOHLeasesholder: {
            type: :integer,
          },
          SubsidyAtRisk: {
            type: :integer,
          },
          EvictionHistory: {
            type: :integer,
          },
          CriminalRecord: {
            type: :integer,
          },
          IncarceratedAdult: {
            type: :integer,
          },
          PrisonDischarge: {
            type: :integer,
          },
          SexOffender: {
            type: :integer,
          },
          DisabledHoH: {
            type: :integer,
          },
          CurrentPregnant: {
            type: :integer,
          },
          SingleParent: {
            type: :integer,
          },
          DependentUnder6: {
            type: :integer,
          },
          HH5Plus: {
            type: :integer,
          },
          CoCPrioritized: {
            type: :integer,
          },
          HPScreeningScore: {
            type: :integer,
          },
          ThresholdScore: {
            type: :integer,
          },
          DateCreated: {
            type: :datetime,
            null: false,
          },
          DateUpdated: {
            type: :datetime,
            null: false,
          },
          UserID: {
            type: :string,
            limit: 32,
            null: false,
          },
          DateDeleted: {
            type: :datetime,
          },
          ExportID: {
            type: :string,
            limit: 32,
            null: false,
          },
        }
      end
    end

    def hmis_indices(version: nil) # rubocop:disable Lint/UnusedMethodArgument
      {
        [:DateCreated] => nil,
        [:DateDeleted] => nil,
        [:DateUpdated] => nil,
        [:EnrollmentID] => nil,
        [:EntryDate] => nil,
        [:PersonalID] => nil,
        [:ProjectID] => nil,
        [:HouseholdID] => nil,
        [:ExportID] => nil,
        [:ProjectID, :HouseholdID] => nil,
        [:EnrollmentID, :PersonalID] => nil,
        [:EnrollmentID, :ProjectID, :EntryDate] => nil,
        [:RelationshipToHoH] => {
          include: [
            :EnrollmentID,
            :PersonalID,
            :ProjectID,
            :EntryDate,
            :HouseholdID,
            :MoveInDate,
            :DisablingCondition,
          ],
        },
        [:ProjectID, :RelationshipToHoH] => {
          include: [
            :EnrollmentID,
            :PersonalID,
            :EntryDate,
            :HouseholdID,
            :MoveInDate,
          ],
        },
        [:LivingSituation] => nil,
        [:PreviousStreetESSH, :LengthOfStay] => nil,
        [:TimesHomelessPastThreeYears, :MonthsHomelessPastThreeYears] => nil,
      }
    end
  end
end
