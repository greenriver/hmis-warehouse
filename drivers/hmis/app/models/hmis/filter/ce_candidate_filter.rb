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
      # Find all opportunities in the unit groups specified (including for deleted units)
      opportunity_ids = Hmis::Ce::Opportunity.
        joins(unit: :unit_group).
        where(ug_t[:id].in(input.exclude_recently_declined_from_unit_group)).
        select(:id)

      # Get most recent declined referral per client to any of these opportunities
      # { source_client_id => most_recent_decline_timestamp }
      most_recent_declines = Hmis::Ce::Referral.rejected.
        where(opportunity_id: opportunity_ids).
        group(:client_id).
        maximum(:completed_at)

      # Map source to destination clients. { source_client_id => dest_client_id }
      source_to_dest_client_map = Hmis::Hud::Client.where(id: most_recent_declines.keys).
        joins(:warehouse_client_source).
        pluck(:id, wc_t[:destination_id]).
        to_h

      # Form identifiers that are referenced in candidate pool criteria for these unit groups
      candidate_pools = Hmis::Ce::Match::CandidatePool.
        joins(:unit_groups).
        where(ug_t[:id].in(input.exclude_recently_declined_from_unit_group)).
        distinct
      form_identifiers = candidate_pools.flat_map(&:relevant_form_definition_identifiers).uniq

      # Get most recent assessment date per client
      # { destination_client_id => max_date_updated_timestamp }
      most_recent_assessment_dates = Hmis::DestinationClientLatestAssessment.
        where(destination_client_id: source_to_dest_client_map.values).
        where(form_identifier: form_identifiers).
        group(:destination_client_id).
        joins(:custom_assessment).
        maximum(cas_t[:date_updated])

      # Exclude clients who have been declined, except those who have since been re-assessed
      excluded_destination_client_ids = most_recent_declines.filter_map do |source_client_id, decline_date|
        destination_client_id = source_to_dest_client_map[source_client_id]
        assessment_date = most_recent_assessment_dates[destination_client_id]

        # Skip (don't exclude) client who has an assessment date more recent than their decline date
        next nil if assessment_date.present? && assessment_date >= decline_date

        destination_client_id
      end
      return scope if excluded_destination_client_ids.blank?

      scope.
        joins(:client_proxy).
        where.not(Hmis::Ce::ClientProxy.arel_table[:client_id].in(excluded_destination_client_ids))
    end
  end
end

# todo @martha - take this out into a query service, refactor nicely into modular methods
