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
    field :event, HmisSchema::Enums::EventType, null: false
    field :referral_result, HmisSchema::Enums::ReferralResult, null: true
    field :location_crisis_or_ph_housing, String, null: true

    def enrollment
      load_ar_association(object, :enrollment)
    end

    def client
      load_ar_association(object, :client)
    end
  end
end
