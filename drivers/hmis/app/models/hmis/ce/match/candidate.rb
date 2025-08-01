# frozen_string_literal: true

# an eligible, prioritized client for a given candidate pool
module Hmis::Ce::Match
  class Candidate < GrdaWarehouseBase
    self.table_name = 'ce_match_candidates'
    belongs_to :candidate_pool, class_name: 'Hmis::Ce::Match::CandidatePool'
    belongs_to :client_proxy, class_name: 'Hmis::Ce::ClientProxy'

    has_many :opportunities, through: :candidate_pool, class_name: 'Hmis::Ce::Opportunity'
    has_many :units, through: :opportunities, class_name: 'Hmis::Unit'
    has_many :unit_groups, through: :units, class_name: 'Hmis::UnitGroup'


    # order by descending priority, NULL values last. Use id as a tie-breaker
    scope :prioritized, -> {
      order(
        arel_table[:priority_score].desc.nulls_last,
        arel_table[:id].asc,
      )
    }

    # Which candidates (clients) are eligible for an opportunity
    scope :for_opportunity, ->(opportunity) do
      return Hmis::Ce::Opportunity.none unless opportunity.candidate_pool

      opportunity.candidate_pool.candidates
    end

    # FIXME make this a multi key has_many association
    def ce_match_candidate_events
      Hmis::Ce::Match::CandidateEvent.where(candidate_pool_id: candidate_pool_id, client_proxy_id: client_proxy_id)
    end

    # We should be able to replace the below "rows" with something like this that can be paginated,
    # but I couldn't figure out how to do it with distinct/grouping. We essentially want one Candidate
    # record per Unit Group.
    def self.all_candidates_by_distinct_unit_group
      Hmis::Ce::Match::Candidate.
        joins(candidate_pool: { opportunities: { unit: :unit_group } }).
        select('ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id').
        distinct
        # select('DISTINCT ON (ce_match_candidates.id, hmis_unit_groups.id) ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id')
        # pass something to count(...) and that might be enough. look at Paginated abstraction and see what you can pass in
        # subquery correlated subquery
        # to_sql to dig into it.
    end

    # "rows" for this client on the "consolidated waitlist" table
    def rows
      client_id = client_proxy.client.id
      client_name = client_proxy.client.full_name
      # fixme- current DS
      source_client_id = client_proxy.client.source_clients.joins(:data_source).merge(GrdaWarehouse::DataSource.hmis).first

      # attributes that contributed to eligibility and priority
      # this should really pull from "cache" on candidate table instead of looking at events
      client_attributes = ce_match_candidate_events.max_by(&:created_at)&.snapshot || {}

      # which projects is this candidate on the waitlist for?
      # project_ids = candidate_pool.opportunities.joins(:project).select(Hmis::Hud::Project.arel_table[:id]).distinct

      # which unit groups is this candidate on the waitlist for?
      # NOTE this assumes we are getting rid of unit-level eligibility, and making unit group the most granular level
      unit_group_ids = candidate_pool.opportunities.preload(:unit).map do |opportunity|
        opportunity.unit.hmis_unit_group_id
      end.uniq
      Hmis::UnitGroup.where(id: unit_group_ids).preload(:opportunities, project: :organization).map do |unit_group|
        project = unit_group.project
        # This could be simplified to:
        # OpenStruct.new(
        #   unit_group: unit_group,
        #   candidate: self,
        # )
        OpenStruct.new(
          id: "#{id}:#{project.id}",
          destination_client_id: client_id,
          source_client_id: source_client_id,
          client_name: client_name,
          unit_group_name: unit_group.name,
          project_name: project.project_name,
          project_id: project.id,
          organization_name: project.organization.organization_name,
          when_added_to_candidate_pool: created_at,
          when_updated_in_candidate_pool: updated_at,
          priority_score: priority_score,
          client_attributes: client_attributes,
          vacancies: unit_group.opportunities.receiving_referrals.count,
          capacity: unit_group.units.count,
          # Y/N has vacancy?
          # TODO eligible vacancy unit_id link? or, just link to Client>Available Units page with prefilter for project
        )
      end
    end
  end
end
