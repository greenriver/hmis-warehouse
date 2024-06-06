###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::IncomeBenefit < Types::BaseObject
    include Types::HmisSchema::HasCustomDataElements
    include Types::HmisSchema::HasHudMetadata

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :information_date, GraphQL::Types::ISO8601Date, null: true

    # Income
    field :income_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    # TODO: We arbitrarily resolve some currency values as Floats and some as Strings.
    # This was based on the IncomeBenefit hmis_configuration. They should be reviewed and standardized.
    field :total_monthly_income, String, null: true

    # Income Booleans
    field :earned, HmisSchema::Enums::Hud::NoYesMissing
    field :unemployment, HmisSchema::Enums::Hud::NoYesMissing
    field :ssi, HmisSchema::Enums::Hud::NoYesMissing
    field :ssdi, HmisSchema::Enums::Hud::NoYesMissing
    field :va_disability_service, HmisSchema::Enums::Hud::NoYesMissing
    field :va_disability_non_service, HmisSchema::Enums::Hud::NoYesMissing
    field :private_disability, HmisSchema::Enums::Hud::NoYesMissing
    field :workers_comp, HmisSchema::Enums::Hud::NoYesMissing
    field :tanf, HmisSchema::Enums::Hud::NoYesMissing
    field :ga, HmisSchema::Enums::Hud::NoYesMissing
    field :soc_sec_retirement, HmisSchema::Enums::Hud::NoYesMissing
    field :pension, HmisSchema::Enums::Hud::NoYesMissing
    field :child_support, HmisSchema::Enums::Hud::NoYesMissing
    field :alimony, HmisSchema::Enums::Hud::NoYesMissing
    field :other_income_source, HmisSchema::Enums::Hud::NoYesMissing

    # Income Amounts
    field :earned_amount, Float, null: true
    field :unemployment_amount, Float, null: true
    field :ssi_amount, Float, null: true
    field :ssdi_amount, Float, null: true
    field :va_disability_service_amount, Float, null: true
    field :va_disability_non_service_amount, Float, null: true
    field :private_disability_amount, Float, null: true
    field :workers_comp_amount, Float, null: true
    field :tanf_amount, Float, null: true
    field :ga_amount, Float, null: true
    field :soc_sec_retirement_amount, Float, null: true
    field :pension_amount, Float, null: true
    field :child_support_amount, Float, null: true
    field :alimony_amount, Float, null: true
    field :other_income_amount, Float, null: true
    field :other_income_source_identify, String, null: true

    # Benefits
    field :benefits_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    field :snap, HmisSchema::Enums::Hud::NoYesMissing
    field :wic, HmisSchema::Enums::Hud::NoYesMissing
    field :tanf_child_care, HmisSchema::Enums::Hud::NoYesMissing
    field :tanf_transportation, HmisSchema::Enums::Hud::NoYesMissing
    field :other_tanf, HmisSchema::Enums::Hud::NoYesMissing
    field :other_benefits_source, HmisSchema::Enums::Hud::NoYesMissing
    field :other_benefits_source_identify, String

    # Health
    field :insurance_from_any_source, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :medicaid, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_medicaid_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :medicare, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_medicare_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :schip, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_schip_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :vha_services, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_vha_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :employer_provided, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_employer_provided_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :cobra, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_cobra_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :private_pay, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_private_pay_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :state_health_ins, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_state_health_ins_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :indian_health_services, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :no_indian_health_services_reason, HmisSchema::Enums::Hud::ReasonNotInsured, null: true
    field :other_insurance, HmisSchema::Enums::Hud::NoYesMissing, null: true
    field :other_insurance_identify, String, null: true

    field :adap, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :no_adap_reason, HmisSchema::Enums::Hud::NoAssistanceReason, null: true
    field :ryan_white_med_dent, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true
    field :no_ryan_white_reason, HmisSchema::Enums::Hud::NoAssistanceReason, null: true
    field :connection_with_soar, HmisSchema::Enums::Hud::NoYesReasonsForMissingData, null: true

    field :data_collection_stage, HmisSchema::Enums::Hud::DataCollectionStage, null: false, default_value: Types::BaseEnum::INVALID_VALUE

    custom_data_elements_field

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
