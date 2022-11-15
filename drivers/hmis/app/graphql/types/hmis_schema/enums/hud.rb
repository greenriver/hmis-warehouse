###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# THIS FILE IS GENERATED, DO NOT EDIT DIRECTLY

module Types::HmisSchema::Enums::Hud
  class ExportPeriodType < Types::BaseEnum
    description '1.1'
    graphql_name 'ExportPeriodType'
    hud_enum :export_period_type_map
  end

  class ExportDirective < Types::BaseEnum
    description '1.2'
    graphql_name 'ExportDirective'
    hud_enum :export_directive_map
  end

  class DisabilityType < Types::BaseEnum
    description '1.3'
    graphql_name 'DisabilityType'
    hud_enum :disability_type_map
  end

  class RecordType < Types::BaseEnum
    description '1.4'
    graphql_name 'RecordType'
    hud_enum :record_type_map
  end

  class HashStatus < Types::BaseEnum
    description '1.5'
    graphql_name 'HashStatus'
    hud_enum :hash_status_map
  end

  class NoYesMissing < Types::BaseEnum
    description '1.7'
    graphql_name 'NoYesMissing'
    hud_enum :no_yes_missing_map
  end

  class NoYesReasonsForMissingData < Types::BaseEnum
    description '1.8'
    graphql_name 'NoYesReasonsForMissingData'
    hud_enum :no_yes_reasons_for_missing_data_map
  end

  class SourceType < Types::BaseEnum
    description '1.9'
    graphql_name 'SourceType'
    hud_enum :source_type_map
  end

  class TrackingMethod < Types::BaseEnum
    description '2.02.C'
    graphql_name 'TrackingMethod'
    hud_enum :tracking_method_map
  end

  class FundingSource < Types::BaseEnum
    description '2.6.1'
    graphql_name 'FundingSource'
    hud_enum :funding_source_map
  end

  class HouseholdType < Types::BaseEnum
    description '2.7.2'
    graphql_name 'HouseholdType'
    hud_enum :household_type_map
  end

  class BedType < Types::BaseEnum
    description '2.7.3'
    graphql_name 'BedType'
    hud_enum :bed_type_map
  end

  class Availability < Types::BaseEnum
    description '2.7.4'
    graphql_name 'Availability'
    hud_enum :availability_map
  end

  class YouthAgeGroup < Types::BaseEnum
    description '2.7.B'
    graphql_name 'YouthAgeGroup'
    hud_enum :youth_age_group_map
  end

  class GeographyType < Types::BaseEnum
    description '2.8.7'
    graphql_name 'GeographyType'
    hud_enum :geography_type_map
  end

  class HousingType < Types::BaseEnum
    description '2.02.D'
    graphql_name 'HousingType'
    hud_enum :housing_type_map
  end

  class TargetPopulation < Types::BaseEnum
    description '2.02.8'
    graphql_name 'TargetPopulation'
    hud_enum :target_population_map
  end

  class NameDataQuality < Types::BaseEnum
    description '3.1.5'
    graphql_name 'NameDataQuality'
    hud_enum :name_data_quality_map
  end

  class SSNDataQuality < Types::BaseEnum
    description '3.2.2'
    graphql_name 'SSNDataQuality'
    hud_enum :ssn_data_quality_map
  end

  class DOBDataQuality < Types::BaseEnum
    description '3.3.2'
    graphql_name 'DOBDataQuality'
    hud_enum :dob_data_quality_map
  end

  class Ethnicity < Types::BaseEnum
    description '3.5.1'
    graphql_name 'Ethnicity'
    hud_enum :ethnicity_map
  end

  class LivingSituation < Types::BaseEnum
    description '3.917.1'
    graphql_name 'LivingSituation'
    hud_enum :living_situation_map
  end

  class ResidencePriorLengthOfStay < Types::BaseEnum
    description '3.917.2'
    graphql_name 'ResidencePriorLengthOfStay'
    hud_enum :residence_prior_length_of_stay_map
  end

  class TimesHomelessPastThreeYears < Types::BaseEnum
    description '3.3917.4'
    graphql_name 'TimesHomelessPastThreeYears'
    hud_enum :times_homeless_past_three_years_map
  end

  class MonthsHomelessPastThreeYears < Types::BaseEnum
    description '3.917.5'
    graphql_name 'MonthsHomelessPastThreeYears'
    hud_enum :months_homeless_past_three_years_map
  end

  class Destination < Types::BaseEnum
    description '3.12.1'
    graphql_name 'Destination'
    hud_enum :destination_map
  end

  class RelationshipToHoH < Types::BaseEnum
    description '3.15.1'
    graphql_name 'RelationshipToHoH'
    hud_enum :relationship_to_ho_h_map
  end

  class HousingStatus < Types::BaseEnum
    description '4.1.1'
    graphql_name 'HousingStatus'
    hud_enum :housing_status_map
  end

  class ReasonNotInsured < Types::BaseEnum
    description '4.04.A'
    graphql_name 'ReasonNotInsured'
    hud_enum :reason_not_insured_map
  end

  class PATHHowConfirmed < Types::BaseEnum
    description '4.9.D'
    graphql_name 'PATHHowConfirmed'
    hud_enum :path_how_confirmed_map
  end

  class PATHSMIInformation < Types::BaseEnum
    description '4.9.E'
    graphql_name 'PATHSMIInformation'
    hud_enum :pathsmi_information_map
  end

  class DisabilityResponse < Types::BaseEnum
    description '4.10.2'
    graphql_name 'DisabilityResponse'
    hud_enum :disability_response_map
  end

  class WhenDVOccurred < Types::BaseEnum
    description '4.11.A'
    graphql_name 'WhenDVOccurred'
    hud_enum :when_dv_occurred_map
  end

  class ContactLocation < Types::BaseEnum
    description '4.12.2'
    graphql_name 'ContactLocation'
    hud_enum :contact_location_map
  end

  class PATHServices < Types::BaseEnum
    description '4.14.A'
    graphql_name 'PATHServices'
    hud_enum :path_services_map
  end

  class RHYServices < Types::BaseEnum
    description '4.14.B'
    graphql_name 'RHYServices'
    hud_enum :rhy_services_map
  end

  class HOPWAMedAssistedLivingFac < Types::BaseEnum
    description '2.02.9'
    graphql_name 'HOPWAMedAssistedLivingFac'
    hud_enum :hopwa_med_assisted_living_fac_map
  end

  class HOPWAServices < Types::BaseEnum
    description '4.14.C'
    graphql_name 'HOPWAServices'
    hud_enum :hopwa_services_map
  end

  class SSVFServices < Types::BaseEnum
    description '4.14.D'
    graphql_name 'SSVFServices'
    hud_enum :ssvf_services_map
  end

  class SSVFSubType3 < Types::BaseEnum
    description '4.14.D3'
    graphql_name 'SSVFSubType3'
    hud_enum :ssvf_sub_type3_map
  end

  class SSVFSubType4 < Types::BaseEnum
    description '4.14.D4'
    graphql_name 'SSVFSubType4'
    hud_enum :ssvf_sub_type4_map
  end

  class SSVFSubType5 < Types::BaseEnum
    description '4.14.D5'
    graphql_name 'SSVFSubType5'
    hud_enum :ssvf_sub_type5_map
  end

  class HOPWAFinancialAssistance < Types::BaseEnum
    description '4.15.A'
    graphql_name 'HOPWAFinancialAssistance'
    hud_enum :hopwa_financial_assistance_map
  end

  class BedNight < Types::BaseEnum
    description '4.14'
    graphql_name 'BedNight'
    hud_enum :bed_night_map
  end

  class SSVFFinancialAssistance < Types::BaseEnum
    description '4.15.B'
    graphql_name 'SSVFFinancialAssistance'
    hud_enum :ssvf_financial_assistance_map
  end

  class PATHReferral < Types::BaseEnum
    description '4.16.A'
    graphql_name 'PATHReferral'
    hud_enum :path_referral_map
  end

  class RHYReferral < Types::BaseEnum
    description '4.16.B'
    graphql_name 'RHYReferral'
    hud_enum :rhy_referral_map
  end

  class PATHReferralOutcome < Types::BaseEnum
    description 'P2.A'
    graphql_name 'PATHReferralOutcome'
    hud_enum :path_referral_outcome_map
  end

  class HousingAssessmentDisposition < Types::BaseEnum
    description '4.18.1'
    graphql_name 'HousingAssessmentDisposition'
    hud_enum :housing_assessment_disposition_map
  end

  class HousingAssessmentAtExit < Types::BaseEnum
    description '4.19.1'
    graphql_name 'HousingAssessmentAtExit'
    hud_enum :housing_assessment_at_exit_map
  end

  class AssessmentType < Types::BaseEnum
    description '4.19.3'
    graphql_name 'AssessmentType'
    hud_enum :assessment_type_map
  end

  class AssessmentLevel < Types::BaseEnum
    description '4.19.4'
    graphql_name 'AssessmentLevel'
    hud_enum :assessment_level_map
  end

  class PrioritizationStatus < Types::BaseEnum
    description '4.19.7'
    graphql_name 'PrioritizationStatus'
    hud_enum :prioritization_status_map
  end

  class SubsidyInformation < Types::BaseEnum
    description '4.19.A'
    graphql_name 'SubsidyInformation'
    hud_enum :subsidy_information_map
  end

  class ReasonNotEnrolled < Types::BaseEnum
    description '4.20.A'
    graphql_name 'ReasonNotEnrolled'
    hud_enum :reason_not_enrolled_map
  end

  class ReferralResult < Types::BaseEnum
    description '4.20.D'
    graphql_name 'ReferralResult'
    hud_enum :referral_result_map
  end

  class EventType < Types::BaseEnum
    description '4.20.2'
    graphql_name 'EventType'
    hud_enum :event_type_map
  end

  class ReasonNoServices < Types::BaseEnum
    description '4.22.A'
    graphql_name 'ReasonNoServices'
    hud_enum :reason_no_services_map
  end

  class SexualOrientation < Types::BaseEnum
    description '4.23.1'
    graphql_name 'SexualOrientation'
    hud_enum :sexual_orientation_map
  end

  class LastGradeCompleted < Types::BaseEnum
    description '4.24.1'
    graphql_name 'LastGradeCompleted'
    hud_enum :last_grade_completed_map
  end

  class SchoolStatus < Types::BaseEnum
    description '4.25.1'
    graphql_name 'SchoolStatus'
    hud_enum :school_status_map
  end

  class EmploymentType < Types::BaseEnum
    description '4.26.A'
    graphql_name 'EmploymentType'
    hud_enum :employment_type_map
  end

  class NotEmployedReason < Types::BaseEnum
    description '4.26.B'
    graphql_name 'NotEmployedReason'
    hud_enum :not_employed_reason_map
  end

  class HealthStatus < Types::BaseEnum
    description '4.27.1'
    graphql_name 'HealthStatus'
    hud_enum :health_status_map
  end

  class RHYNumberofYears < Types::BaseEnum
    description '4.31.A'
    graphql_name 'RHYNumberofYears'
    hud_enum :rhy_numberof_years_map
  end

  class IncarceratedParentStatus < Types::BaseEnum
    description '4.33.A'
    graphql_name 'IncarceratedParentStatus'
    hud_enum :incarcerated_parent_status_map
  end

  class ReferralSource < Types::BaseEnum
    description '4.34.1'
    graphql_name 'ReferralSource'
    hud_enum :referral_source_map
  end

  class CountExchangeForSex < Types::BaseEnum
    description '4.35.A'
    graphql_name 'CountExchangeForSex'
    hud_enum :count_exchange_for_sex_map
  end

  class ExitAction < Types::BaseEnum
    description '4.36.1'
    graphql_name 'ExitAction'
    hud_enum :exit_action_map
  end

  class ProjectCompletionStatus < Types::BaseEnum
    description '4.37.1'
    graphql_name 'ProjectCompletionStatus'
    hud_enum :project_completion_status_map
  end

  class EarlyExitReason < Types::BaseEnum
    description '4.37.A'
    graphql_name 'EarlyExitReason'
    hud_enum :early_exit_reason_map
  end

  class ExpelledReason < Types::BaseEnum
    description '4.37.B'
    graphql_name 'ExpelledReason'
    hud_enum :expelled_reason_map
  end

  class WorkerResponse < Types::BaseEnum
    description 'R19.A'
    graphql_name 'WorkerResponse'
    hud_enum :worker_response_map
  end

  class AftercareProvided < Types::BaseEnum
    description 'R20.2'
    graphql_name 'AftercareProvided'
    hud_enum :aftercare_provided_map
  end

  class NoAssistanceReason < Types::BaseEnum
    description '4.39'
    graphql_name 'NoAssistanceReason'
    hud_enum :no_assistance_reason_map
  end

  class MilitaryBranch < Types::BaseEnum
    description '4.41.11'
    graphql_name 'MilitaryBranch'
    hud_enum :military_branch_map
  end

  class DischargeStatus < Types::BaseEnum
    description '4.41.12'
    graphql_name 'DischargeStatus'
    hud_enum :discharge_status_map
  end

  class PercentAMI < Types::BaseEnum
    description '4.42.1'
    graphql_name 'PercentAMI'
    hud_enum :percent_ami_map
  end

  class AddressDataQuality < Types::BaseEnum
    description '4.43.5'
    graphql_name 'AddressDataQuality'
    hud_enum :address_data_quality_map
  end

  class VamcsStationNumber < Types::BaseEnum
    description 'V6.1'
    graphql_name 'VamcsStationNumber'
    hud_enum :vamcs_station_number_map
  end

  class TCellSourceViralLoadSource < Types::BaseEnum
    description '4.47.B'
    graphql_name 'TCellSourceViralLoadSource'
    hud_enum :t_cell_source_viral_load_source_map
  end

  class ViralLoadAvailable < Types::BaseEnum
    description '4.47.3'
    graphql_name 'ViralLoadAvailable'
    hud_enum :viral_load_available_map
  end

  class NoPointsYes < Types::BaseEnum
    description '4.48.1'
    graphql_name 'NoPointsYes'
    hud_enum :no_points_yes_map
  end

  class TimeToHousingLoss < Types::BaseEnum
    description '4.48.2'
    graphql_name 'TimeToHousingLoss'
    hud_enum :time_to_housing_loss_map
  end

  class AnnualPercentAMI < Types::BaseEnum
    description '4.48.4'
    graphql_name 'AnnualPercentAMI'
    hud_enum :annual_percent_ami_map
  end

  class EvictionHistory < Types::BaseEnum
    description '4.48.7'
    graphql_name 'EvictionHistory'
    hud_enum :eviction_history_map
  end

  class LiteralHomelessHistory < Types::BaseEnum
    description '4.48.9'
    graphql_name 'LiteralHomelessHistory'
    hud_enum :literal_homeless_history_map
  end

  class IncarceratedAdult < Types::BaseEnum
    description 'V7.I'
    graphql_name 'IncarceratedAdult'
    hud_enum :incarcerated_adult_map
  end

  class DependentUnder6 < Types::BaseEnum
    description 'V7.O'
    graphql_name 'DependentUnder6'
    hud_enum :dependent_under6_map
  end

  class VoucherTracking < Types::BaseEnum
    description 'V8.1'
    graphql_name 'VoucherTracking'
    hud_enum :voucher_tracking_map
  end

  class CmExitReason < Types::BaseEnum
    description 'V9.1'
    graphql_name 'CmExitReason'
    hud_enum :cm_exit_reason_map
  end

  class CrisisServicesUse < Types::BaseEnum
    description '4.49.1'
    graphql_name 'CrisisServicesUse'
    hud_enum :crisis_services_use_map
  end

  class DataCollectionStage < Types::BaseEnum
    description '5.03.1'
    graphql_name 'DataCollectionStage'
    hud_enum :data_collection_stage_map
  end

  class AdHocYesNo < Types::BaseEnum
    description 'ad_hoc_yes_no'
    graphql_name 'AdHocYesNo'
    hud_enum :ad_hoc_yes_no_map
  end

  class WellbeingAgreement < Types::BaseEnum
    description 'C1.1'
    graphql_name 'WellbeingAgreement'
    hud_enum :wellbeing_agreement_map
  end

  class FeelingFrequency < Types::BaseEnum
    description 'C1.2'
    graphql_name 'FeelingFrequency'
    hud_enum :feeling_frequency_map
  end

  class MovingOnAssistance < Types::BaseEnum
    description 'C2.2'
    graphql_name 'MovingOnAssistance'
    hud_enum :moving_on_assistance_map
  end

  class CurrentSchoolAttended < Types::BaseEnum
    description 'C3.2'
    graphql_name 'CurrentSchoolAttended'
    hud_enum :current_school_attended_map
  end

  class MostRecentEdStatus < Types::BaseEnum
    description 'C3.A'
    graphql_name 'MostRecentEdStatus'
    hud_enum :most_recent_ed_status_map
  end

  class CurrentEdStatus < Types::BaseEnum
    description 'C3.B'
    graphql_name 'CurrentEdStatus'
    hud_enum :current_ed_status_map
  end
end
