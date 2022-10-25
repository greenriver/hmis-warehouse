###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Service < Types::BaseObject
    description 'HUD Service'
    field :id, ID, null: false
    field :enrollment, Types::HmisSchema::Enrollment, null: false
    field :client, HmisSchema::Client, null: false
    field :date_provided, GraphQL::Types::ISO8601Date, null: false
    field :record_type, HmisSchema::Enums::RecordType, null: false
    field :type_provided, HmisSchema::Enums::ServiceTypeProvided, null: false
    field :other_type_provided, String, null: true
    field :moving_on_other_type, String, null: true
    field :sub_type_provided, HmisSchema::Enums::ServiceSubTypeProvided, null: true
    field 'FAAmount', Float, null: true
    field :referral_outcome, HmisSchema::Enums::PATHReferralOutcome, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: true
    field :user, HmisSchema::User, null: false

    def user
      load_ar_association(object, :user)
    end

    def type_provided
      [object.record_type, object.type_provided].join(':')
    end

    def sub_type_provided
      return nil unless object.sub_type_provided.present?

      [type_provided, object.sub_type_provided].join(':')
    end
  end
end
