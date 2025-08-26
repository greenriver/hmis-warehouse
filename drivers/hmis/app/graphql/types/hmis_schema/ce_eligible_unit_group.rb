###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeEligibleUnitGroup < Types::BaseObject
    # This type represents a specific eligibility relationship between a CE Candidate and Unit Group.
    # object is a Hmis::Ce::Match::Candidate with unit_group_id

    field :id, ID, null: false
    field :unit_group_name, String, null: false
    field :project_name, String, null: false
    field :project_id, ID, null: false
    field :project_type, HmisSchema::Enums::ProjectType, null: false
    field :organization_name, String, null: false
    field :units_accepting_referrals, Integer, null: false, description: 'Number of units in the unit group that are currently accepting referrals'
    field :candidate_created_at, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at, description: 'Timestamp when the candidate was added to the pool'
    field :candidate_updated_at, GraphQL::Types::ISO8601DateTime, null: false, method: :updated_at, description: 'Timestamp when the candidate was last updated'

    def id
      "#{object.id}:#{object.unit_group_id}"
    end

    def unit_group_name
      unit_group.name
    end

    def project_name
      project.project_name
    end

    def project_id
      project.id
    end

    def project_type
      project.project_type
    end

    def organization_name
      load_ar_association(project, :organization)&.organization_name
    end

    def units_accepting_referrals
      load_ar_association(unit_group, :opportunities).filter(&:receiving_referrals?).count
    end

    private

    def unit_group
      load_ar_scope(scope: Hmis::UnitGroup, id: object.unit_group_id)
    end

    def project
      load_ar_association(unit_group, :project)
    end
  end
end
