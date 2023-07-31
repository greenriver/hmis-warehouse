###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY
module Types::HmisSchema::Enums::Hud
  class ExportPeriodType < Types::BaseEnum
    description '1.1'
    graphql_name 'ExportPeriodType'
    hud_enum HudUtility.period_types
  end

  class ExportDirective < Types::BaseEnum
    description '1.2'
    graphql_name 'ExportDirective'
    hud_enum HudUtility.export_directives
  end

  class DisabilityType < Types::BaseEnum
    description '1.3'
    graphql_name 'DisabilityType'
    hud_enum HudUtility.disability_types
  end

  class RecordType < Types::BaseEnum
    description '1.4'
    graphql_name 'RecordType'
    hud_enum HudUtility.record_types
  end

  class HashStatus < Types::BaseEnum
    description '1.5'
    graphql_name 'HashStatus'
    hud_enum HudUtility.hash_statuses
  end

  class NoYesMissing < Types::BaseEnum
    description '1.7'
    graphql_name 'NoYesMissing'
    hud_enum HudUtility.yes_no_missing_options
  end

  class NoYesReasonsForMissingData < Types::BaseEnum
    description '1.8'
    graphql_name 'NoYesReasonsForMissingData'
    hud_enum HudUtility.no_yes_reasons_for_missing_data_options
  end

  class SourceType < Types::BaseEnum
    description '1.9'
    graphql_name 'SourceType'
    hud_enum HudUtility.source_types
  end

  class TargetPopulation < Types::BaseEnum
    description '2.02.8'
    graphql_name 'TargetPopulation'
    hud_enum HudUtility.target_populations
  end

  class HOPWAMedAssistedLivingFac < Types::BaseEnum
    description '2.02.9'
    graphql_name 'HOPWAMedAssistedLivingFac'
    hud_enum HudUtility.hopwa_med_assisted_living_facs
  end

  class TrackingMethod < Types::BaseEnum
    description '2.02.C'
    graphql_name 'TrackingMethod'
    hud_enum HudUtility.tracking_methods
  end

  class HousingType < Types::BaseEnum
    description '2.02.D'
    graphql_name 'HousingType'
    hud_enum HudUtility.housing_types
  end

  class ProjectType < Types::BaseEnum
    description '2.02.6'
    graphql_name 'ProjectType'
    hud_enum HudUtility.project_types
  end

  class ProjectTypeBrief < Types::BaseEnum
    description '2.02.6.brief'
    graphql_name 'ProjectTypeBrief'
    hud_enum HudUtility.project_type_briefs
  end

  class FundingSource < Types::BaseEnum
    description '2.06.1'
    graphql_name 'FundingSource'
    hud_enum HudUtility.funding_sources
  end

  class HouseholdType < Types::BaseEnum
    description '2.07.4'
    graphql_name 'HouseholdType'
    hud_enum HudUtility.household_types
  end

  class BedType < Types::BaseEnum
    description '2.07.5'
    graphql_name 'BedType'
    hud_enum HudUtility.bed_types
  end

  class Availability < Types::BaseEnum
    description '2.07.6'
    graphql_name 'Availability'
    hud_enum HudUtility.availabilities
  end

  class YouthAgeGroup < Types::BaseEnum
    description '2.7.B'
    graphql_name 'YouthAgeGroup'
    hud_enum HudUtility.youth_age_groups
  end

  class GeographyType < Types::BaseEnum
    description '2.03.4'
    graphql_name 'GeographyType'
    hud_enum HudUtility.geography_types
  end

  class NameDataQuality < Types::BaseEnum
    description '3.01.5'
    graphql_name 'NameDataQuality'
    hud_enum HudUtility.name_data_quality_options
  end

  class Destination < Types::BaseEnum
    description '3.12.1'
    graphql_name 'Destination'
    hud_enum HudUtility.destinations
  end

  class RelationshipToHoH < Types::BaseEnum
    description '3.15.1'
    graphql_name 'RelationshipToHoH'
    hud_enum HudUtility.relationships_to_hoh
  end

  class SSNDataQuality < Types::BaseEnum
    description '3.02.2'
    graphql_name 'SSNDataQuality'
    hud_enum HudUtility.ssn_data_quality_options
  end

  class DOBDataQuality < Types::BaseEnum
    description '3.03.2'
    graphql_name 'DOBDataQuality'
    hud_enum HudUtility.dob_data_quality_options
  end

  class TimesHomelessPastThreeYears < Types::BaseEnum
    description '3.917.4'
    graphql_name 'TimesHomelessPastThreeYears'
    hud_enum HudUtility.times_homeless_options
  end

  class Ethnicity < Types::BaseEnum
    description '3.05.1'
    graphql_name 'Ethnicity'
    hud_enum HudUtility.ethnicities
  end

  class LivingSituation < Types::BaseEnum
    description '3.12.1'
    graphql_name 'LivingSituation'
    hud_enum HudUtility.living_situations
  end

  class ResidencePriorLengthOfStay < Types::BaseEnum
    description '3.917.2'
    graphql_name 'ResidencePriorLengthOfStay'
    hud_enum HudUtility.length_of_stays
  end

  class MonthsHomelessPastThreeYears < Types::BaseEnum
    description '3.917.5'
    graphql_name 'MonthsHomelessPastThreeYears'
    hud_enum HudUtility.month_categories
  end

  class ReasonNotInsured < Types::BaseEnum
    description '4.04.A'
    graphql_name 'ReasonNotInsured'
    hud_enum HudUtility.reason_not_insureds
  end

  class HousingStatus < Types::BaseEnum
    description '4.1.1'
    graphql_name 'HousingStatus'
    hud_enum HudUtility.housing_statuses
  end

  class DisabilityResponse < Types::BaseEnum
    description '4.10.2'
    graphql_name 'DisabilityResponse'
    hud_enum HudUtility.disability_responses
  end

  class WhenDVOccurred < Types::BaseEnum
    description '4.11.A'
    graphql_name 'WhenDVOccurred'
    hud_enum HudUtility.when_occurreds
  end

  class ContactLocation < Types::BaseEnum
    description '4.12.2'
    graphql_name 'ContactLocation'
    hud_enum HudUtility.contact_locations
  end

  class BedNight < Types::BaseEnum
    description '4.14'
    graphql_name 'BedNight'
    hud_enum HudUtility.bed_night_options
  end

  class RHYServices < Types::BaseEnum
    description '4.14.B'
    graphql_name 'RHYServices'
    hud_enum HudUtility.rhy_services_options
  end

  class SSVFFinancialAssistance < Types::BaseEnum
    description '4.15.B'
    graphql_name 'SSVFFinancialAssistance'
    hud_enum HudUtility.ssvf_financial_assistance_options
  end

  class HousingAssessmentDisposition < Types::BaseEnum
    description '4.18.1'
    graphql_name 'HousingAssessmentDisposition'
    hud_enum HudUtility.housing_assessment_dispositions
  end

  class AssessmentType < Types::BaseEnum
    description '4.19.3'
    graphql_name 'AssessmentType'
    hud_enum HudUtility.assessment_types
  end

  class AssessmentLevel < Types::BaseEnum
    description '4.19.4'
    graphql_name 'AssessmentLevel'
    hud_enum HudUtility.assessment_levels
  end

  class PrioritizationStatus < Types::BaseEnum
    description '4.19.7'
    graphql_name 'PrioritizationStatus'
    hud_enum HudUtility.prioritization_statuses
  end

  class EventType < Types::BaseEnum
    description '4.20.2'
    graphql_name 'EventType'
    hud_enum HudUtility.events
  end

  class ReferralResult < Types::BaseEnum
    description '4.20.D'
    graphql_name 'ReferralResult'
    hud_enum HudUtility.referral_results
  end

  # Only present in 2024 spec
  class RentalSubsidyType < Types::BaseEnum
    description '3.12.A'
    graphql_name 'RentalSubsidyType'
    hud_enum ::HudLists2024.rental_subsidy_type_map
  end

  class IncarceratedParentStatus < Types::BaseEnum
    description '4.33.A'
    graphql_name 'IncarceratedParentStatus'
    hud_enum HudUtility.incarcerated_parent_statuses
  end

  class ExitAction < Types::BaseEnum
    description '4.36.1'
    graphql_name 'ExitAction'
    hud_enum HudUtility.exit_actions
  end

  class EarlyExitReason < Types::BaseEnum
    description '4.37.A'
    graphql_name 'EarlyExitReason'
    hud_enum HudUtility.early_exit_reasons
  end

  class CrisisServicesUse < Types::BaseEnum
    description '4.49.1'
    graphql_name 'CrisisServicesUse'
    hud_enum HudUtility.crisis_services_uses
  end

  class PATHHowConfirmed < Types::BaseEnum
    description '4.9.D'
    graphql_name 'PATHHowConfirmed'
    hud_enum HudUtility.path_how_confirmeds
  end

  class PATHSMIInformation < Types::BaseEnum
    description '4.9.E'
    graphql_name 'PATHSMIInformation'
    hud_enum HudUtility.pathsmi_informations
  end

  class DataCollectionStage < Types::BaseEnum
    description '5.03.1'
    graphql_name 'DataCollectionStage'
    hud_enum HudUtility.data_collection_stages
  end

  class WellbeingAgreement < Types::BaseEnum
    description 'C1.1'
    graphql_name 'WellbeingAgreement'
    hud_enum HudUtility.wellbeing_agreements
  end

  class FeelingFrequency < Types::BaseEnum
    description 'C1.2'
    graphql_name 'FeelingFrequency'
    hud_enum HudUtility.feeling_frequencies
  end

  class MovingOnAssistance < Types::BaseEnum
    description 'C2.2'
    graphql_name 'MovingOnAssistance'
    hud_enum HudUtility.moving_on_assistance_options
  end

  class CurrentSchoolAttended < Types::BaseEnum
    description 'C3.2'
    graphql_name 'CurrentSchoolAttended'
    hud_enum HudUtility.current_school_attendeds
  end

  class MostRecentEdStatus < Types::BaseEnum
    description 'C3.A'
    graphql_name 'MostRecentEdStatus'
    hud_enum HudUtility.most_recent_ed_statuses
  end

  class CurrentEdStatus < Types::BaseEnum
    description 'C3.B'
    graphql_name 'CurrentEdStatus'
    hud_enum HudUtility.current_ed_statuses
  end

  class PATHServices < Types::BaseEnum
    description 'P1.2'
    graphql_name 'PATHServices'
    hud_enum HudUtility.path_services_options
  end

  class PATHReferral < Types::BaseEnum
    description 'P2.2'
    graphql_name 'PATHReferral'
    hud_enum HudUtility.path_referral_options
  end

  class PATHReferralOutcome < Types::BaseEnum
    description 'P2.A'
    graphql_name 'PATHReferralOutcome'
    hud_enum HudUtility.path_referral_outcomes
  end

  class ReasonNotEnrolled < Types::BaseEnum
    description 'P3.A'
    graphql_name 'ReasonNotEnrolled'
    hud_enum HudUtility.reason_not_enrolleds
  end

  class ReferralSource < Types::BaseEnum
    description 'R1.1'
    graphql_name 'ReferralSource'
    hud_enum HudUtility.referral_sources
  end

  class RHYNumberofYears < Types::BaseEnum
    description 'R11.A'
    graphql_name 'RHYNumberofYears'
    hud_enum HudUtility.rhy_numberof_years_options
  end

  class RHYReferral < Types::BaseEnum
    description 'R14.2'
    graphql_name 'RHYReferral'
    hud_enum HudUtility.rhy_referral_options
  end

  class CountExchangeForSex < Types::BaseEnum
    description 'R15.B'
    graphql_name 'CountExchangeForSex'
    hud_enum HudUtility.count_exchange_for_sexes
  end

  class ProjectCompletionStatus < Types::BaseEnum
    description 'R17.1'
    graphql_name 'ProjectCompletionStatus'
    hud_enum HudUtility.project_completion_statuses
  end

  class ExpelledReason < Types::BaseEnum
    description 'R17.A'
    graphql_name 'ExpelledReason'
    hud_enum HudUtility.expelled_reasons
  end

  class WorkerResponse < Types::BaseEnum
    description 'R19.A'
    graphql_name 'WorkerResponse'
    hud_enum HudUtility.worker_responses
  end

  class ReasonNoServices < Types::BaseEnum
    description 'R2.A'
    graphql_name 'ReasonNoServices'
    hud_enum HudUtility.reason_no_services_options
  end

  class AftercareProvided < Types::BaseEnum
    description 'R20.2'
    graphql_name 'AftercareProvided'
    hud_enum HudUtility.aftercare_provideds
  end

  class SexualOrientation < Types::BaseEnum
    description 'R3.1'
    graphql_name 'SexualOrientation'
    hud_enum HudUtility.sexual_orientations
  end

  class LastGradeCompleted < Types::BaseEnum
    description 'R4.1'
    graphql_name 'LastGradeCompleted'
    hud_enum HudUtility.last_grade_completeds
  end

  class SchoolStatus < Types::BaseEnum
    description 'R5.1'
    graphql_name 'SchoolStatus'
    hud_enum HudUtility.school_statuses
  end

  class EmploymentType < Types::BaseEnum
    description 'R6.A'
    graphql_name 'EmploymentType'
    hud_enum HudUtility.employment_types
  end

  class NotEmployedReason < Types::BaseEnum
    description 'R6.B'
    graphql_name 'NotEmployedReason'
    hud_enum HudUtility.not_employed_reasons
  end

  class HealthStatus < Types::BaseEnum
    description 'R7.1'
    graphql_name 'HealthStatus'
    hud_enum HudUtility.health_statuses
  end

  class MilitaryBranch < Types::BaseEnum
    description 'V1.11'
    graphql_name 'MilitaryBranch'
    hud_enum HudUtility.military_branches
  end

  class DischargeStatus < Types::BaseEnum
    description 'V1.12'
    graphql_name 'DischargeStatus'
    hud_enum HudUtility.discharge_statuses
  end

  class SSVFServices < Types::BaseEnum
    description 'V2.2'
    graphql_name 'SSVFServices'
    hud_enum HudUtility.ssvf_services_options
  end

  class HOPWAFinancialAssistance < Types::BaseEnum
    description 'V2.3'
    graphql_name 'HOPWAFinancialAssistance'
    hud_enum HudUtility.hopwa_financial_assistance_options
  end

  class SSVFSubType3 < Types::BaseEnum
    description 'V2.A'
    graphql_name 'SSVFSubType3'
    hud_enum HudUtility.ssvf_sub_type3s
  end

  class SSVFSubType4 < Types::BaseEnum
    description 'V2.B'
    graphql_name 'SSVFSubType4'
    hud_enum HudUtility.ssvf_sub_type4s
  end

  class SSVFSubType5 < Types::BaseEnum
    description 'V2.C'
    graphql_name 'SSVFSubType5'
    hud_enum HudUtility.ssvf_sub_type5s
  end

  class PercentAMI < Types::BaseEnum
    description 'V4.1'
    graphql_name 'PercentAMI'
    hud_enum HudUtility.percent_amis
  end

  class AddressDataQuality < Types::BaseEnum
    description 'V5.5'
    graphql_name 'AddressDataQuality'
    hud_enum HudUtility.address_data_qualities
  end

  class VamcsStationNumber < Types::BaseEnum
    description 'V6.1'
    graphql_name 'VamcsStationNumber'
    hud_enum HudUtility.vamcs_station_numbers
  end

  class NoPointsYes < Types::BaseEnum
    description 'V7.1'
    graphql_name 'NoPointsYes'
    hud_enum HudUtility.no_points_yes_options
  end

  class TimeToHousingLoss < Types::BaseEnum
    description 'V7.A'
    graphql_name 'TimeToHousingLoss'
    hud_enum HudUtility.time_to_housing_losses
  end

  class AnnualPercentAMI < Types::BaseEnum
    description 'V7.B'
    graphql_name 'AnnualPercentAMI'
    hud_enum HudUtility.annual_percent_amis
  end

  class LiteralHomelessHistory < Types::BaseEnum
    description 'V7.C'
    graphql_name 'LiteralHomelessHistory'
    hud_enum HudUtility.literal_homeless_histories
  end

  class EvictionHistory < Types::BaseEnum
    description 'V7.G'
    graphql_name 'EvictionHistory'
    hud_enum HudUtility.eviction_histories
  end

  class IncarceratedAdult < Types::BaseEnum
    description 'V7.I'
    graphql_name 'IncarceratedAdult'
    hud_enum HudUtility.incarcerated_adults
  end

  class DependentUnder6 < Types::BaseEnum
    description 'V7.O'
    graphql_name 'DependentUnder6'
    hud_enum HudUtility.dependent_under_6_options
  end

  class VoucherTracking < Types::BaseEnum
    description 'V8.1'
    graphql_name 'VoucherTracking'
    hud_enum HudUtility.voucher_tracking_options
  end

  class CmExitReason < Types::BaseEnum
    description 'V9.1'
    graphql_name 'CmExitReason'
    hud_enum HudUtility.cm_exit_reasons
  end

  class HOPWAServices < Types::BaseEnum
    description 'W1.2'
    graphql_name 'HOPWAServices'
    hud_enum HudUtility.hopwa_services_options
  end

  class NoAssistanceReason < Types::BaseEnum
    description 'W3'
    graphql_name 'NoAssistanceReason'
    hud_enum HudUtility.no_assistance_reasons
  end

  class ViralLoadAvailable < Types::BaseEnum
    description 'W4.3'
    graphql_name 'ViralLoadAvailable'
    hud_enum HudUtility.viral_load_availables
  end

  class TCellSourceViralLoadSource < Types::BaseEnum
    description 'W4.B'
    graphql_name 'TCellSourceViralLoadSource'
    hud_enum HudUtility.t_cell_source_viral_load_sources
  end

  class HousingAssessmentAtExit < Types::BaseEnum
    description 'W5.1'
    graphql_name 'HousingAssessmentAtExit'
    hud_enum HudUtility.housing_assessment_at_exits
  end

  class SubsidyInformation < Types::BaseEnum
    description 'W5.A'
    graphql_name 'SubsidyInformation'
    hud_enum HudUtility.subsidy_informations
  end

  class AdHocYesNo < Types::BaseEnum
    description 'ad_hoc_yes_no'
    graphql_name 'AdHocYesNo'
    hud_enum HudUtility.ad_hoc_yes_nos
  end
end
