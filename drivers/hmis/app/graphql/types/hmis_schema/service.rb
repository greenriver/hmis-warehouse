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
    # field :type_provided
    field :other_type_provided, String, null: true
    field :moving_on_other_type, String, null: true
    # field :sub_type_provided
    field :faa_amount, Float, null: true
    field :referral_outcome, HmisSchema::Enums::PATHReferralOutcome, null: true
    field :date_created, GraphQL::Types::ISO8601DateTime, null: false
    field :date_updated, GraphQL::Types::ISO8601DateTime, null: false
    field :date_deleted, GraphQL::Types::ISO8601DateTime, null: false
    # field :user, HmisSchema::User, null: false
    # field :export, HmisSchema::Export, null: false

    # TODO: Add user type?
    # def user
    #   load_ar_association(object, :user)
    # end

    # TODO: Add export type?
    # def export
    #   load_ar_association(object, :export)
    # end
  end
end
