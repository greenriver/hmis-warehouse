###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeOpportunity < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :status, String, null: false
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true
    field :active_referral, Types::HmisSchema::CeReferral, null: true
    field :candidates, [Types::HmisSchema::CeCandidate], null: false

    def candidates
      Hmis::Ce::Match::Candidate.
        for_opportunity(object).
        order(priority_score: :desc, client_id: :desc).
        limit(50) # FIXME: add pagination. Just limit to top 50 for now
    end

    def active_referral
      object.referrals.order(:id).viewable_by(current_user).active.first
    end
  end
end
