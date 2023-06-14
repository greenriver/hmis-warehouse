###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Exit < Types::BaseObject
    def self.configuration
      Hmis::Hud::Exit.hmis_configuration(version: '2022')
    end

    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :user, HmisSchema::User, null: true
    # 3.11
    hud_field :exit_date, null: false
    # 3.12
    hud_field :destination, Types::HmisSchema::Enums::Hud::Destination, null: false
    hud_field :destination_subsidy_type, Types::HmisSchema::Enums::Hud::RentalSubsidyType
    hud_field :other_destination
    # W5
    hud_field :housing_assessment, Types::HmisSchema::Enums::Hud::HousingAssessmentAtExit
    hud_field :subsidy_information, Types::HmisSchema::Enums::Hud::SubsidyInformation
    # R17
    hud_field :project_completion_status, Types::HmisSchema::Enums::Hud::ProjectCompletionStatus
    hud_field :early_exit_reason, Types::HmisSchema::Enums::Hud::ExpelledReason
    # R15
    hud_field :exchange_for_sex, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :exchange_for_sex_past_three_months, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :count_of_exchange_for_sex, Types::HmisSchema::Enums::Hud::CountExchangeForSex
    hud_field :asked_or_forced_to_exchange_for_sex, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :asked_or_forced_to_exchange_for_sex_past_three_months, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    # R16
    hud_field :workplace_violence_threats, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :workplace_promise_difference, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :coerced_to_continue_work, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :labor_exploit_past_three_months, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    # R18
    hud_field :counseling_received, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :individual_counseling, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :family_counseling, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :group_counseling, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :session_count_at_exit, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :post_exit_counseling_plan, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :sessions_in_plan, Int
    # R19
    hud_field :destination_safe_client, Types::HmisSchema::Enums::Hud::NoYesReasonsForMissingData
    hud_field :destination_safe_worker, Types::HmisSchema::Enums::Hud::WorkerResponse
    hud_field :pos_adult_connections, Types::HmisSchema::Enums::Hud::WorkerResponse
    hud_field :pos_peer_connections, Types::HmisSchema::Enums::Hud::WorkerResponse
    hud_field :pos_community_connections, Types::HmisSchema::Enums::Hud::WorkerResponse
    # R20
    hud_field :aftercare_date, GraphQL::Types::ISO8601Date
    hud_field :aftercare_provided, Types::HmisSchema::Enums::Hud::AftercareProvided
    hud_field :email_social_media, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :telephone, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :in_person_individual, Types::HmisSchema::Enums::Hud::NoYesMissing
    hud_field :in_person_group, Types::HmisSchema::Enums::Hud::NoYesMissing
    # V1
    hud_field :cm_exit_reason, Types::HmisSchema::Enums::Hud::CmExitReason
    hud_field :date_updated
    hud_field :date_created
    hud_field :date_deleted

    # TODO: FPDE

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
