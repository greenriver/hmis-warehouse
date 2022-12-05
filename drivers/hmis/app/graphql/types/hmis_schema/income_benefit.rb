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
    field :user, HmisSchema::User, null: false
    hud_field :information_date
    # hud_field :income_from_any_source
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
