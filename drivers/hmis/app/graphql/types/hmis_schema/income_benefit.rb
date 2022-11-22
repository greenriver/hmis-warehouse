###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::IncomeBenefit < Types::BaseObject
    def self.configuration
      Hmis::Hud::IncomeBenefit.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    hud_field :information_date

    # Income
    hud_field :income_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :total_monthly_income
    # hud_field :earned
    hud_field :earned_amount
    # hud_field :unemployment
    hud_field :unemployment_amount
    # hud_field :ssi
    hud_field :ssi_amount
    # hud_field :ssdi
    hud_field :ssdi_amount
    # hud_field :va_disability_service
    hud_field :va_disability_service_amount
    # hud_field :va_disability_non_service
    hud_field :va_disability_non_service_amount
    # hud_field :private_disability
    hud_field :private_disability_amount
    # hud_field :workers_comp
    hud_field :workers_comp_amount
    # hud_field :tanf
    hud_field :tanf_amount
    # hud_field :ga
    hud_field :ga_amount
    # hud_field :soc_sec_retirement
    hud_field :soc_sec_retirement_amount
    # hud_field :pension
    hud_field :pension_amount
    # hud_field :child_support
    hud_field :child_support_amount
    # hud_field :alimony
    hud_field :alimony_amount
    # hud_field :other_income_source
    hud_field :other_income_amount
    hud_field :other_income_source_identify

    # Benefits
    hud_field :benefits_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    yes_no_missing_field :snap
    yes_no_missing_field :wic
    yes_no_missing_field :tanf_child_care
    yes_no_missing_field :tanf_transportation
    yes_no_missing_field :other_tanf
    yes_no_missing_field :other_benefits_source
    hud_field :other_benefits_source_identify

    # Health
    hud_field :insurance_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    yes_no_missing_field :medicaid
    hud_field :no_medicaid_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :medicare
    hud_field :no_medicare_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :schip
    hud_field :no_schip_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :va_medical_services
    hud_field :no_va_med_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :employer_provided
    hud_field :no_employer_provided_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :cobra
    hud_field :no_cobra_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :private_pay
    hud_field :no_private_pay_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :state_health_ins
    hud_field :no_state_health_ins_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :indian_health_services
    hud_field :no_indian_health_services_reason, HmisSchema::Enums::Hud::ReasonNotInsured
    yes_no_missing_field :other_insurance
    hud_field :other_insurance_identify

    hud_field :hivaids_assistance, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :no_hivaids_assistance_reason, HmisSchema::Enums::Hud::NoAssistanceReason
    hud_field :adap, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :no_adap_reason, HmisSchema::Enums::Hud::NoAssistanceReason
    hud_field :ryan_white_med_dent, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :no_ryan_white_reason, HmisSchema::Enums::Hud::NoAssistanceReason
    hud_field :connection_with_soar, HmisSchema::Enums::Hud::NoYesReasonsForMissingData

    hud_field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    # TODO ADD: source assessment

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end

    def user
      load_ar_association(object, :user)
    end
  end
end
