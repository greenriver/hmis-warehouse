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
    field :capacity, Integer, null: false, description: 'Total number of units in the unit group'
    field :vacancies, Integer, null: false, description: 'Number of units that are accepting referrals'
    field :when_added_to_candidate_pool, GraphQL::Types::ISO8601DateTime, null: false, method: :created_at
    field :when_updated_in_candidate_pool, GraphQL::Types::ISO8601DateTime, null: false, method: :updated_at

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

    def vacancies
      unit_group.opportunities.receiving_referrals.count # FIXME perf - load UnitGroup type and let it resolve this stuff?
    end

    def capacity
      unit_group.units.count # FIXME perf - load UnitGroup type and let it resolve this stuff?
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
