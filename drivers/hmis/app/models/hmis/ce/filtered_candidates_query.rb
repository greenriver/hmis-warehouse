###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Hmis::Ce
  # Query for Coordinated Entry opportunity candidates with an option to filter
  # clients who have recently declined a referral.
  #
  # This filter identifies clients who have been declined from any opportunity within
  # the same unit group as the target opportunity.
  #
  # An exception is made for clients who have been re-assessed since their most
  # recent decline. Since a re-assessment may change their eligibility, they are
  # included in the candidate list regardless of the recent decline.
  #
  class FilteredCandidatesQuery
    def arel = Hmis::ArelHelper.instance

    def initialize(opportunity:, exclude_recently_declined: false)
      @opportunity = opportunity
      @unit_group_id = opportunity.unit_group.id
      @exclude_recently_declined = exclude_recently_declined
      @base_candidate_scope = Hmis::Ce::Match::Candidate.for_opportunity(opportunity).prioritized
    end

    def resolve
      return @base_candidate_scope unless @exclude_recently_declined

      # { source_client_id => most_recent_decline_timestamp }
      most_recent_declines = fetch_most_recent_declines
      return @base_candidate_scope if most_recent_declines.blank?

      # { source_client_id => dest_client_id }
      source_to_dest_client_map = map_source_to_dest_clients(most_recent_declines.keys)
      # source_to_dest_client_map could be empty if a declined client had no destination client.
      # For now, this could only happen with a direct referral, since candidacy for waitlists is destination client based.
      # In the future, this could happen if we include more types of clients on waitlists, such as VSP clients.
      # Either way, if we can't find the client to exclude, just return the original unfiltered scope.
      return @base_candidate_scope if source_to_dest_client_map.blank?

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
      # Find all opportunities in this opportunity's unit group (including for deleted units)
      opportunity_ids = Hmis::Ce::Opportunity.
        joins(unit: :unit_group).
        where(arel.ug_t[:id].eq(@unit_group_id)).
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
        pluck(:id, arel.wc_t[:destination_id]).
        to_h
    end

    def fetch_most_recent_assessment_dates(dest_client_ids)
      # Form identifiers that are referenced in candidate pool criteria for these unit groups
      candidate_pools = Hmis::Ce::Match::CandidatePool.
        joins(:unit_groups).
        where(arel.ug_t[:id].eq(@unit_group_id)).
        distinct
      form_identifiers = candidate_pools.flat_map(&:relevant_form_definition_identifiers).uniq

      # Get most recent assessment date per client
      Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: dest_client_ids).
        where(form_identifier: form_identifiers).
        group(:destination_client_id).
        joins(:custom_assessment).
        maximum(arel.cas_t[:date_updated])
    end

    def determine_client_ids_to_exclude(most_recent_declines, most_recent_assessment_dates, source_to_dest_client_map)
      most_recent_declines.filter_map do |source_client_id, decline_date|
        destination_client_id = source_to_dest_client_map[source_client_id]
        assessment_date = most_recent_assessment_dates[destination_client_id]

        # Exclude this client, unless they have been reassessed since the decline
        destination_client_id if assessment_date.blank? || assessment_date <= decline_date
      end
    end

    def filter_candidates(client_ids_to_exclude)
      @base_candidate_scope.
        joins(:client_proxy).
        where.not(Hmis::Ce::ClientProxy.arel_table[:client_id].in(client_ids_to_exclude))
    end
  end
end
