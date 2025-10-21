###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class Hmis::Filter::CeCandidateFilter < Hmis::Filter::BaseFilter
  include ::Hmis::Concerns::HmisArelHelper # todo @martha - remove?

  def filter_scope(scope)
    scope = ensure_scope(scope)
    scope.
      yield_self(&method(:exclude_recently_declined_from_unit_group)).
      yield_self(&method(:clean_scope))
  end

  protected

  def exclude_recently_declined_from_unit_group(scope)
    with_filter(scope, :exclude_recently_declined_from_unit_group) do
      # input.exclude_recently_declined_from_unit_group

      # find all opportunities in this unit group (including for deleted units)
      # other_opportunities_in_unit_group = Hmis::Ce::Opportunity.joins(unit: :unit_group).where(Hmis::UnitGroup.arel_table[:id].eq(unit_group_id))
      #
      # # Get all declined referrals to any of these opportunities
      # # { client_id => [declined_at, ...], ... }
      # all_declines = Hmis::Ce::Referral.rejected.
      #   where(opportunity_id: other_opportunities_in_unit_group.select(:id)).
      #   pluck(:client_id, :completed_at).
      #   group_by(&:first)
      #
      # declined_source_clients = Hmis::Hud::Client.where(id: all_declines.map(&:first))
      #
      # # form identifiers that are referenced in candidate pool criteria
      # form_identifiers = object.candidate_pool.relevant_form_definition_identifiers
      #
      # # Get most recent assessment date per client in a single query to avoid N+1
      # most_recent_assessment_dates = Hmis::Hud::CustomAssessment.
      #   where(client: declined_source_clients).
      #   with_form_definition_identifier(form_identifiers).
      #   group(:client_id). # this wont work, but you get the idea
      #   maximum(:date_updated)
      #
      # # drop declines where the client has been re-assessed since the decline
      # client_ids_to_exclude = most_recent_declines.reject do |client_id, decline_timestamps|
      #   most_recent_assessment_timestamp = most_recent_assessment_dates[client_id]
      #   most_recent_decline_timestamp = decline_timestamps.max
      #   most_recent_assessment_timestamp && most_recent_assessment_timestamp > most_recent_decline_timestamp
      # end.map(&:first)
      scope
    end
  end
end
