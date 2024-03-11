###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY
module Types::HmisSchema::Enums::Hud
  class ExportPeriodType < Types::BaseEnum
    description '1.1'
    graphql_name 'ExportPeriodType'
    hud_enum HudUtility2024.period_types
  end

  class ExportDirective < Types::BaseEnum
    description '1.2'
    graphql_name 'ExportDirective'
    hud_enum HudUtility2024.export_directives
  end

  class DisabilityType < Types::BaseEnum
    description '1.3'
    graphql_name 'DisabilityType'
    hud_enum HudUtility2024.disability_types
  end

  class RecordType < Types::BaseEnum
    description '1.4'
    graphql_name 'RecordType'
    hud_enum HudUtility2024.record_types
  end

  class HashStatus < Types::BaseEnum
    description '1.5'
    graphql_name 'HashStatus'
    hud_enum HudUtility2024.hash_statuses
  end

  class NoYesMissing < Types::BaseEnum
    description '1.7'
    graphql_name 'NoYesMissing'
    hud_enum HudUtility2024.yes_no_missing_options
  end

  class NoYesReasonsForMissingData < Types::BaseEnum
    description '1.8'
    graphql_name 'NoYesReasonsForMissingData'
    hud_enum HudUtility2024.no_yes_reasons_for_missing_data_options
  end

  class SourceType < Types::BaseEnum
    description '1.9'
    graphql_name 'SourceType'
    hud_enum HudUtility2024.source_types
  end

  class NoYes < Types::BaseEnum
    description '1.10'
    graphql_name 'NoYes'
    hud_enum HudUtility2024.no_yes_options
  end

  class RRHSubType < Types::BaseEnum
    description '2.02.A'
    graphql_name 'RRHSubType'
    hud_enum HudUtility2024.rrh_sub_types
  end

  class HousingType < Types::BaseEnum
    description '2.02.D'
    graphql_name 'HousingType'
    hud_enum HudUtility2024.housing_types
  end

  class ProjectType < Types::BaseEnum
    description '2.02.6'
    graphql_name 'ProjectType'
    hud_enum HudUtility2024.project_types
  end

  class ProjectTypeBrief < Types::BaseEnum
    description '2.02.6.brief'
    graphql_name 'ProjectTypeBrief'
    hud_enum HudUtility2024.project_type_briefs
  end

  class TargetPopulation < Types::BaseEnum
    description '2.02.7'
    graphql_name 'TargetPopulation'
    hud_enum HudUtility2024.target_populations
  end

  class HOPWAMedAssistedLivingFac < Types::BaseEnum
    description '2.02.8'
    graphql_name 'HOPWAMedAssistedLivingFac'
    hud_enum HudUtility2024.hopwa_med_assisted_living_facs
  end

  class CoCCodes < Types::BaseEnum
    description '2.03.1'
    graphql_name 'CoCCodes'
    hud_enum HudUtility2024.coc_codes_options
  end

  class GeographyType < Types::BaseEnum
    description '2.03.4'
    graphql_name 'GeographyType'
    hud_enum HudUtility2024.geography_types
  end

  class FundingSource < Types::BaseEnum
    description '2.06.1'
    graphql_name 'FundingSource'
    hud_enum HudUtility2024.funding_sources
  end

  class HouseholdType < Types::BaseEnum
    description '2.07.4'
    graphql_name 'HouseholdType'
    hud_enum HudUtility2024.household_types
  end

  class BedType < Types::BaseEnum
    description '2.07.5'
    graphql_name 'BedType'
    hud_enum HudUtility2024.bed_types
  end

  class Availability < Types::BaseEnum
    description '2.07.6'
    graphql_name 'Availability'
    hud_enum HudUtility2024.availabilities
  end

  class HMISParticipationType < Types::BaseEnum
    description '2.08.1'
    graphql_name 'HMISParticipationType'
    hud_enum HudUtility2024.hmis_participation_types
  end

  class NameDataQuality < Types::BaseEnum
    description '3.01.5'
    graphql_name 'NameDataQuality'
    hud_enum HudUtility2024.name_data_quality_options
  end

  class SSNDataQuality < Types::BaseEnum
    description '3.02.2'
    graphql_name 'SSNDataQuality'
    hud_enum HudUtility2024.ssn_data_quality_options
  end

  class DOBDataQuality < Types::BaseEnum
    description '3.03.2'
    graphql_name 'DOBDataQuality'
    hud_enum HudUtility2024.dob_data_quality_options
  end

  class Destination < Types::BaseEnum
    description '3.12'
    graphql_name 'Destination'
    hud_enum HudUtility2024.destinations
  end

  class RentalSubsidyType < Types::BaseEnum
    description '3.12.A'
    graphql_name 'RentalSubsidyType'
    hud_enum HudUtility2024.rental_subsidy_types
  end

  class CurrentLivingSituation < Types::BaseEnum
    description '3.12.1'
    graphql_name 'CurrentLivingSituationOptions'
    hud_enum HudUtility2024.current_living_situations
  end

  class RelationshipToHoH < Types::BaseEnum
    description '3.15.1'
    graphql_name 'RelationshipToHoH'
    hud_enum HudUtility2024.relationships_to_hoh
  end

  class PriorLivingSituation < Types::BaseEnum
    description '3.917'
    graphql_name 'PriorLivingSituation'
    hud_enum HudUtility2024.prior_living_situations
  end

  class ResidencePriorLengthOfStay < Types::BaseEnum
    description '3.917.2'
    graphql_name 'ResidencePriorLengthOfStay'
    hud_enum HudUtility2024.length_of_stays
  end

  class TimesHomelessPastThreeYears < Types::BaseEnum
    description '3.917.4'
    graphql_name 'TimesHomelessPastThreeYears'
    hud_enum HudUtility2024.times_homeless_options
  end

  class MonthsHomelessPastThreeYears < Types::BaseEnum
    description '3.917.5'
    graphql_name 'MonthsHomelessPastThreeYears'
    hud_enum HudUtility2024.month_categories
  end

  class ReasonNotInsured < Types::BaseEnum
    description '4.04.A'
    graphql_name 'ReasonNotInsured'
    hud_enum HudUtility2024.reason_not_insureds
  end

  class DisabilityResponse < Types::BaseEnum
    description '4.10.2'
    graphql_name 'DisabilityResponse'
    hud_enum HudUtility2024.disability_responses
  end

  class WhenDVOccurred < Types::BaseEnum
    description '4.11.A'
    graphql_name 'WhenDVOccurred'
    hud_enum HudUtility2024.when_occurreds
  end

  class BedNight < Types::BaseEnum
    description '4.14'
    graphql_name 'BedNight'
    hud_enum HudUtility2024.bed_night_options
  end

  class AssessmentType < Types::BaseEnum
    description '4.19.3'
    graphql_name 'AssessmentType'
    hud_enum HudUtility2024.assessment_types
  end

  class AssessmentLevel < Types::BaseEnum
    description '4.19.4'
    graphql_name 'AssessmentLevel'
    hud_enum HudUtility2024.assessment_levels
  end

  class PrioritizationStatus < Types::BaseEnum
    description '4.19.7'
    graphql_name 'PrioritizationStatus'
    hud_enum HudUtility2024.prioritization_statuses
  end

  class ReferralResult < Types::BaseEnum
    description '4.20.D'
    graphql_name 'ReferralResult'
    hud_enum HudUtility2024.referral_results
  end

  class EventType < Types::BaseEnum
    description '4.20.2'
    graphql_name 'EventType'
    hud_enum HudUtility2024.events
  end

  class DataCollectionStage < Types::BaseEnum
    description '5.03.1'
    graphql_name 'DataCollectionStage'
    hud_enum HudUtility2024.data_collection_stages
  end

  class RHYServices < Types::BaseEnum
    description 'R14.2'
    graphql_name 'RHYServices'
    hud_enum HudUtility2024.rhy_services_options
  end

  class SSVFFinancialAssistance < Types::BaseEnum
    description 'V3.3'
    graphql_name 'SSVFFinancialAssistance'
    hud_enum HudUtility2024.ssvf_financial_assistance_options
  end

  class EarlyExitReason < Types::BaseEnum
    description 'R17.A'
    graphql_name 'EarlyExitReason'
    hud_enum HudUtility2024.early_exit_reasons
  end

  class MovingOnAssistance < Types::BaseEnum
    description 'C2.2'
    graphql_name 'MovingOnAssistance'
    hud_enum HudUtility2024.moving_on_assistance_options
  end

  class CurrentSchoolAttended < Types::BaseEnum
    description 'C3.2'
    graphql_name 'CurrentSchoolAttended'
    hud_enum HudUtility2024.current_school_attendeds
  end

  class MostRecentEdStatus < Types::BaseEnum
    description 'C3.A'
    graphql_name 'MostRecentEdStatus'
    hud_enum HudUtility2024.most_recent_ed_statuses
  end

  class CurrentEdStatus < Types::BaseEnum
    description 'C3.B'
    graphql_name 'CurrentEdStatus'
    hud_enum HudUtility2024.current_ed_statuses
  end

  class PATHServices < Types::BaseEnum
    description 'P1.2'
    graphql_name 'PATHServices'
    hud_enum HudUtility2024.path_services_options
  end

  class PATHReferral < Types::BaseEnum
    description 'P2.2'
    graphql_name 'PATHReferral'
    hud_enum HudUtility2024.path_referral_options
  end

  class PATHReferralOutcome < Types::BaseEnum
    description 'P2.A'
    graphql_name 'PATHReferralOutcome'
    hud_enum HudUtility2024.path_referral_outcomes
  end

  class ReasonNotEnrolled < Types::BaseEnum
    description 'P3.A'
    graphql_name 'ReasonNotEnrolled'
    hud_enum HudUtility2024.reason_not_enrolleds
  end

  class ReferralSource < Types::BaseEnum
    description 'R1.1'
    graphql_name 'ReferralSource'
    hud_enum HudUtility2024.referral_sources
  end

  class RHYNumberofYears < Types::BaseEnum
    description 'R11.A'
    graphql_name 'RHYNumberofYears'
    hud_enum HudUtility2024.rhy_numberof_years_options
  end

  class CountExchangeForSex < Types::BaseEnum
    description 'R15.B'
    graphql_name 'CountExchangeForSex'
    hud_enum HudUtility2024.count_exchange_for_sexes
  end

  class ProjectCompletionStatus < Types::BaseEnum
    description 'R17.1'
    graphql_name 'ProjectCompletionStatus'
    hud_enum HudUtility2024.project_completion_statuses
  end

  class ExpelledReason < Types::BaseEnum
    description 'R17.A'
    graphql_name 'ExpelledReason'
    hud_enum HudUtility2024.expelled_reasons
  end

  class WorkerResponse < Types::BaseEnum
    description 'R19.A'
    graphql_name 'WorkerResponse'
    hud_enum HudUtility2024.worker_responses
  end

  class ReasonNoServices < Types::BaseEnum
    description 'R2.A'
    graphql_name 'ReasonNoServices'
    hud_enum HudUtility2024.reason_no_services_options
  end

  class AftercareProvided < Types::BaseEnum
    description 'R20.2'
    graphql_name 'AftercareProvided'
    hud_enum HudUtility2024.aftercare_provideds
  end

  class SexualOrientation < Types::BaseEnum
    description 'R3.1'
    graphql_name 'SexualOrientation'
    hud_enum HudUtility2024.sexual_orientations
  end

  class LastGradeCompleted < Types::BaseEnum
    description 'R4.1'
    graphql_name 'LastGradeCompleted'
    hud_enum HudUtility2024.last_grade_completeds
  end

  class SchoolStatus < Types::BaseEnum
    description 'R5.1'
    graphql_name 'SchoolStatus'
    hud_enum HudUtility2024.school_statuses
  end

  class EmploymentType < Types::BaseEnum
    description 'R6.A'
    graphql_name 'EmploymentType'
    hud_enum HudUtility2024.employment_types
  end

  class NotEmployedReason < Types::BaseEnum
    description 'R6.B'
    graphql_name 'NotEmployedReason'
    hud_enum HudUtility2024.not_employed_reasons
  end

  class HealthStatus < Types::BaseEnum
    description 'R7.1'
    graphql_name 'HealthStatus'
    hud_enum HudUtility2024.health_statuses
  end

  class MilitaryBranch < Types::BaseEnum
    description 'V1.11'
    graphql_name 'MilitaryBranch'
    hud_enum HudUtility2024.military_branches
  end

  class DischargeStatus < Types::BaseEnum
    description 'V1.12'
    graphql_name 'DischargeStatus'
    hud_enum HudUtility2024.discharge_statuses
  end

  class SSVFServices < Types::BaseEnum
    description 'V2.2'
    graphql_name 'SSVFServices'
    hud_enum HudUtility2024.ssvf_services_options
  end

  class HOPWAFinancialAssistance < Types::BaseEnum
    description 'W2.2'
    graphql_name 'HOPWAFinancialAssistance'
    hud_enum HudUtility2024.hopwa_financial_assistance_options
  end

  class SSVFSubType3 < Types::BaseEnum
    description 'V2.A'
    graphql_name 'SSVFSubType3'
    hud_enum HudUtility2024.ssvf_sub_type3s
  end

  class SSVFSubType4 < Types::BaseEnum
    description 'V2.B'
    graphql_name 'SSVFSubType4'
    hud_enum HudUtility2024.ssvf_sub_type4s
  end

  class SSVFSubType5 < Types::BaseEnum
    description 'V2.C'
    graphql_name 'SSVFSubType5'
    hud_enum HudUtility2024.ssvf_sub_type5s
  end

  class PercentAMI < Types::BaseEnum
    description 'V4.1'
    graphql_name 'PercentAMI'
    hud_enum HudUtility2024.percent_amis
  end

  class VamcStationNumber < Types::BaseEnum
    description 'V6.1'
    graphql_name 'VamcStationNumber'
    hud_enum HudUtility2024.vamc_station_numbers
  end

  class TimeToHousingLoss < Types::BaseEnum
    description 'V7.A'
    graphql_name 'TimeToHousingLoss'
    hud_enum HudUtility2024.time_to_housing_losses
  end

  class AnnualPercentAMI < Types::BaseEnum
    description 'V7.B'
    graphql_name 'AnnualPercentAMI'
    hud_enum HudUtility2024.annual_percent_amis
  end

  class LiteralHomelessHistory < Types::BaseEnum
    description 'V7.C'
    graphql_name 'LiteralHomelessHistory'
    hud_enum HudUtility2024.literal_homeless_histories
  end

  class EvictionHistory < Types::BaseEnum
    description 'V7.G'
    graphql_name 'EvictionHistory'
    hud_enum HudUtility2024.eviction_histories
  end

  class IncarceratedAdult < Types::BaseEnum
    description 'V7.I'
    graphql_name 'IncarceratedAdult'
    hud_enum HudUtility2024.incarcerated_adults
  end

  class DependentUnder6 < Types::BaseEnum
    description 'V7.O'
    graphql_name 'DependentUnder6'
    hud_enum HudUtility2024.dependent_under_6_options
  end

  class VoucherTracking < Types::BaseEnum
    description 'V8.2'
    graphql_name 'VoucherTracking'
    hud_enum HudUtility2024.voucher_tracking_options
  end

  class CmExitReason < Types::BaseEnum
    description 'V9.1'
    graphql_name 'CmExitReason'
    hud_enum HudUtility2024.cm_exit_reasons
  end

  class HOPWAServices < Types::BaseEnum
    description 'W1.2'
    graphql_name 'HOPWAServices'
    hud_enum HudUtility2024.hopwa_services_options
  end

  class NoAssistanceReason < Types::BaseEnum
    description 'W3'
    graphql_name 'NoAssistanceReason'
    hud_enum HudUtility2024.no_assistance_reasons
  end

  class ViralLoadAvailable < Types::BaseEnum
    description 'W4.3'
    graphql_name 'ViralLoadAvailable'
    hud_enum HudUtility2024.viral_load_availables
  end

  class TCellSourceViralLoadSource < Types::BaseEnum
    description 'W4.B'
    graphql_name 'TCellSourceViralLoadSource'
    hud_enum HudUtility2024.t_cell_source_viral_load_sources
  end

  class HousingAssessmentAtExit < Types::BaseEnum
    description 'W5.1'
    graphql_name 'HousingAssessmentAtExit'
    hud_enum HudUtility2024.housing_assessment_at_exits
  end

  class SubsidyInformation < Types::BaseEnum
    description 'W5.AB'
    graphql_name 'SubsidyInformation'
    hud_enum HudUtility2024.subsidy_informations
  end

  class AdHocYesNo < Types::BaseEnum
    description 'ad_hoc_yes_no'
    graphql_name 'AdHocYesNo'
    hud_enum HudUtility2024.ad_hoc_yes_nos
  end

  class PreferredLanguage < Types::BaseEnum
    description 'C4.A'
    graphql_name 'PreferredLanguage'
    hud_enum HudUtility2024.preferred_languages
  end

  class SubsidyInformationB < Types::BaseEnum
    description 'W5.B'
    graphql_name 'SubsidyInformationB'
    hud_enum HudUtility2024.subsidy_information_bs
  end
end
