###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeReferralNote < Types::BaseObject
    # object is a Hmis::Ce::ReferralNote

    field :id, ID, null: false
    field :note, String, null: false
    field :user, Application::User, null: true, description: 'The user who created the note'
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false

    def user
      load_ar_association(object, :user)
    end
  end
end
