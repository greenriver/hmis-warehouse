###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Event < Types::BaseObject
    include Types::HmisSchema::HasHudMetadata

    description 'HUD Event'
    field :id, ID, null: false
    field :enrollment, HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :event_date, GraphQL::Types::ISO8601Date, null: false
    field :event, HmisSchema::Enums::Hud::EventType, null: false
    field :referral_result, HmisSchema::Enums::Hud::ReferralResult, null: true
    field :location_crisis_or_ph_housing, String, null: true
    hud_field :prob_sol_div_rr_result, HmisSchema::Enums::Hud::NoYesMissing
    hud_field :referral_case_manage_after, HmisSchema::Enums::Hud::NoYesMissing
    field :result_date, GraphQL::Types::ISO8601Date, null: true

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
