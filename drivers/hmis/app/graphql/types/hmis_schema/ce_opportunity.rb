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
    field :accepted_referral, Types::HmisSchema::CeReferral, null: true
    field :candidates, Types::HmisSchema::CeCandidate.page_type, null: false
    field :project_id, ID, null: false
    field :project_name, String, null: false

    def candidates
      Hmis::Ce::Match::Candidate.
        for_opportunity(object).
        order(priority_score: :desc, client_id: :desc)
    end

    def active_referral
      object.referrals.order(:id).viewable_by(current_user).active.first
    end

    def accepted_referral
      object.referrals.order(:id).viewable_by(current_user).accepted.first
    end

    def project_name
      load_ar_association(object, :project).project_name
    end
  end
end
