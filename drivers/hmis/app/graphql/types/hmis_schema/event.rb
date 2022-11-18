###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Event < Types::BaseObject
    description 'HUD Event'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :event_date, GraphQL::Types::ISO8601DateTime, null: false
    field :event, HmisSchema::Enums::Hud::EventType, null: false
    field :referral_result, HmisSchema::Enums::Hud::ReferralResult, null: true
    field :location_crisis_or_ph_housing, String, null: true
    yes_no_missing_field :prob_sol_div_rr_result
    yes_no_missing_field :referral_case_manage_after
    field :result_date, GraphQL::Types::ISO8601DateTime, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    field :user, HmisSchema::User, null: false

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
