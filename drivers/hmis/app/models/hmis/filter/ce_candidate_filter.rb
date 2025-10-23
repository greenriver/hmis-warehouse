###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeCandidateFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:exclude_recently_declined_from_unit_group)).
      yield_self(&method(:clean_scope))
  end

  protected

  def exclude_recently_declined_from_unit_group(scope)
    with_filter(scope, :exclude_recently_declined_from_unit_group) do
      # find all opportunities in this unit group (including for deleted units)
      opportunities_in_excluded_groups = Hmis::Ce::Opportunity.
        joins(unit: :unit_group).
        where(ug_t[:id].in(input.exclude_recently_declined_from_unit_group))

      # Get most recent declined referral per client to any of these opportunities
      # { client_id => most_recent_declined_at, ... }
      most_recent_declines = Hmis::Ce::Referral.rejected.
        where(opportunity_id: opportunities_in_excluded_groups.select(:id)).
        group(:client_id).
        maximum(:completed_at)

      declined_source_clients = Hmis::Hud::Client.where(id: most_recent_declines.keys)

      hmis_to_dest_client_map = declined_source_clients.
        joins(:warehouse_client_source).
        pluck(:id, wc_t[:destination_id]).
        to_h

      # form identifiers that are referenced in candidate pool criteria
      candidate_pools = Hmis::Ce::Match::CandidatePool.
        joins(:unit_groups).
        where(ug_t[:id].in(input.exclude_recently_declined_from_unit_group)).
        distinct
      form_identifiers = candidate_pools.flat_map(&:relevant_form_definition_identifiers).uniq

      # Get most recent assessment date per client
      # Returns hash: { destination_client_id => max_date_updated_timestamp }
      most_recent_assessment_dates = Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: hmis_to_dest_client_map.values).
        where(form_identifier: form_identifiers).
        group(:destination_client_id).
        joins(:custom_assessment).
        maximum(cas_t[:date_updated])

      # exclude clients who have been declined, except those who have since been re-assessed
      client_ids_to_exclude = most_recent_declines.select do |hmis_client_id, decline_date|
        destination_client_id = hmis_to_dest_client_map[hmis_client_id]
        next unless destination_client_id

        assessment_date = most_recent_assessment_dates[destination_client_id]
        assessment_date.nil? || assessment_date <= decline_date
      end.keys

      excluded_destination_client_ids = hmis_to_dest_client_map.values_at(*client_ids_to_exclude).compact
      return scope if excluded_destination_client_ids.blank?

      scope.joins(:client_proxy).
        where.not(Hmis::Ce::ClientProxy.arel_table[:client_id].in(excluded_destination_client_ids))
    end
  end
end

# todo @martha - take this out into a query service, refactor nicely into modular methods
