###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# usage:
# Hmis::Ce::FilteredCandidatesQuery.
#   new(candidate_scope: scope, exclude_recently_declined_from_unit_group_ids: []).
#   resolve
module Hmis::Ce
  class FilteredCandidatesQuery
    include ::Hmis::Concerns::HmisArelHelper

    def initialize(candidate_scope:, exclude_recently_declined_from_unit_group_ids:)
      @base_candidate_scope = candidate_scope
      @unit_groups_ids = exclude_recently_declined_from_unit_group_ids
    end

    def resolve
      return @base_candidate_scope if @unit_groups_ids.blank?

      # { source_client_id => most_recent_decline_timestamp }
      most_recent_declines = fetch_most_recent_declines
      return @base_candidates if most_recent_declines.blank?

      # { source_client_id => dest_client_id }
      source_to_dest_client_map = map_source_to_dest_clients(most_recent_declines.keys)
      return @base_candidates if source_to_dest_client_map.blank? # unexpected

      # { dest_client_id => most_recent_assessment_update_timestamp }
      most_recent_assessment_dates = fetch_most_recent_assessment_dates(source_to_dest_client_map.values)

      client_ids_to_exclude = determine_client_ids_to_exclude(
        most_recent_declines,
        most_recent_assessment_dates,
        source_to_dest_client_map,
      )

      return @base_candidate_scope if client_ids_to_exclude.blank?

      filter_candidates(client_ids_to_exclude)
    end

    private

    def fetch_most_recent_declines
      # Find all opportunities in the unit groups specified (including for deleted units)
      opportunity_ids = Hmis::Ce::Opportunity.
        joins(unit: :unit_group).
        where(ug_t[:id].in(@unit_groups_ids)).
        select(:id)

      # Get most recent declined referral per client to any of these opportunities
      Hmis::Ce::Referral.rejected.
        where(opportunity_id: opportunity_ids).
        group(:client_id).
        maximum(:completed_at)
    end

    def map_source_to_dest_clients(source_client_ids)
      Hmis::Hud::Client.where(id: source_client_ids).
        joins(:warehouse_client_source).
        pluck(:id, wc_t[:destination_id]).
        to_h
    end

    def fetch_most_recent_assessment_dates(dest_client_ids)
      # Form identifiers that are referenced in candidate pool criteria for these unit groups
      candidate_pools = Hmis::Ce::Match::CandidatePool.
        joins(:unit_groups).
        where(ug_t[:id].in(@unit_groups_ids)).
        distinct
      form_identifiers = candidate_pools.flat_map(&:relevant_form_definition_identifiers).uniq

      # Get most recent assessment date per client
      Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: dest_client_ids).
        where(form_identifier: form_identifiers).
        group(:destination_client_id).
        joins(:custom_assessment).
        maximum(cas_t[:date_updated])
    end

    def determine_client_ids_to_exclude(most_recent_declines, most_recent_assessment_dates, source_to_dest_client_map)
      # Exclude clients who have been declined, except those who have since been re-assessed
      most_recent_declines.filter_map do |source_client_id, decline_date|
        destination_client_id = source_to_dest_client_map[source_client_id]
        assessment_date = most_recent_assessment_dates[destination_client_id]

        # Skip (don't exclude) client who has an assessment date more recent than their decline date
        next nil if assessment_date.present? && assessment_date >= decline_date

        destination_client_id
      end
    end

    def filter_candidates(client_ids_to_exclude)
      @base_candidate_scope.
        joins(:client_proxy).
        where.not(Hmis::Ce::ClientProxy.arel_table[:client_id].in(client_ids_to_exclude))
    end
  end
end
