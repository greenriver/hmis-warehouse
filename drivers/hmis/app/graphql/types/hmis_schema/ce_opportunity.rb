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
    field :status, HmisSchema::Enums::CeOpportunityStatus, null: false
    field :expires_at, GraphQL::Types::ISO8601DateTime, null: true
    field :referral, Types::HmisSchema::CeReferral, null: true, description: 'Active or accepted referral'
    field :candidates, Types::HmisSchema::CeCandidate.page_type, null: false

    # Resolve project fields separately, instead of the whole project object, in case user can't view the project
    field :project_id, ID, null: false
    field :project_name, String, null: false
    field :project_type, HmisSchema::Enums::ProjectType, null: false

    field :eligibility_requirements, [HmisSchema::CeMatchRule], null: true
    field :priority_scheme, HmisSchema::CeMatchRule, null: true
    field :categories, [String], null: false
    field :active, Boolean, null: false, method: :active?
    field :candidates_generated_at, GraphQL::Types::ISO8601DateTime, null: true

    available_filter_options do
      arg :status, [HmisSchema::Enums::CeOpportunityStatus]
      arg :project, [ID]
      arg :project_type, [HmisSchema::Enums::ProjectType]
    end

    def candidates
      Hmis::Ce::Match::Candidate.
        for_opportunity(object).
        order(priority_score: :desc, client_id: :desc)
    end

    def referral
      load_ar_association(
        object,
        :referrals,
        scope: Hmis::Ce::Referral.viewable_by(current_user).where.not(status: 'rejected').
          order(created_at: :desc),
      ).first
    end

    def project_name
      load_ar_association(object, :project).project_name
    end

    def project_type
      load_ar_association(object, :project).project_type
    end

    def eligibility_requirements
      # not to be used in batch
      Hmis::Ce::Match::Rule.eligibility_requirement.for_opportunity(object)
    end

    def priority_scheme
      # not to be used in batch
      Hmis::Ce::Match::Rule.priority_scheme.for_opportunity(object).first # there should only be 1
    end

    def categories
      load_ar_association(object, :categories, scope: Hmis::Ce::OpportunityCategory.order(:name)).map(&:name)
    end

    def candidates_generated_at
      load_ar_association(object, :candidate_pool)&.candidates_generated_at
    end
  end
end
