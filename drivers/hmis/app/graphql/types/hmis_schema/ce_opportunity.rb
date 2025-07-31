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
    field :organization_name, String, null: false

    field :eligibility_requirements, [HmisSchema::CeMatchRule], null: true
    field :priority_schemes, [HmisSchema::CeMatchRule], null: true
    field :categories, [String], null: false
    field :active, Boolean, null: false, method: :active?
    field :candidates_generated_at, GraphQL::Types::ISO8601DateTime, null: true
    field :date_available, GraphQL::Types::ISO8601Date, null: false
    field :unit, HmisSchema::Unit, null: true

    available_filter_options do
      arg :status, [HmisSchema::Enums::CeOpportunityStatus]
      arg :project, [ID]
      arg :project_type, [HmisSchema::Enums::ProjectType]
      arg :organization, [ID]
      arg :available_on_date, GraphQL::Types::ISO8601Date
      arg :workflow_template, [String]
    end

    field :candidate_lookup, Types::HmisSchema::CeCandidate, null: true do
      argument :id, ID, required: true
    end

    # View candidate details when creating a referral. (Source enrollment selection step)
    def candidate_lookup(id:)
      access_denied! unless current_permission?(permission: :can_view_prioritized_client_lists, entity: object.project)

      Hmis::Ce::Match::Candidate.for_opportunity(object).find_by(id: id)
    end

    def candidates # not for batch
      return Hmis::Ce::Match::Candidate.none unless policy_for(object, policy_type: :ce_opportunity).can_view_candidates?

      Hmis::Ce::Match::Candidate.for_opportunity(object).prioritized
    end

    def referral
      referral = load_ar_association(object, :active_or_accepted_referral)
      return if referral.nil?

      # Permission logic lives on the viewable_by scope, so just reuse that here
      # (even though this field doesn't need to be resolved in batch)
      load_ar_scope(scope: Hmis::Ce::Referral.viewable_by(current_user), id: referral.id)
    end

    def project_name
      load_ar_association(object, :project).project_name
    end

    def project_type
      load_ar_association(object, :project).project_type
    end

    def organization_name
      project = load_ar_association(object, :project)
      load_ar_association(project, :organization).name
    end

    def unit
      load_ar_association(object, :unit)
    end

    def date_available
      # TODO(#7537) - implement "available after date". Always returns date the referral was created, for now
      object.created_at
    end

    def eligibility_requirements
      # not to be used in batch
      Hmis::Ce::Match::Rule.eligibility_requirement.for_opportunity(object)
    end

    def priority_schemes
      # not to be used in batch
      Hmis::Ce::Match::Rule.priority_scheme.for_opportunity(object).by_rank
    end

    def categories
      load_ar_association(object, :categories).to_a.sort_by(&:name).map(&:name)
    end

    def candidates_generated_at
      load_ar_association(object, :candidate_pool)&.candidates_generated_at
    end
  end
end
