###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# ClientProxy supports flexibility and deduplication of clients on CE referral waitlists.
# Hmis::Ce::Match::Candidate refers to this class instead of directly to a client record.
# - Proxy class allows more flexibility to point at other records (such as non-HMIS VSP clients)
# - Using destination client ensures clients are deduplicated on waitlists, even if they are duplicated in source client records.
# - Destination client also allows use of full client data to determine eligibility (e.g., open enrollments across deduplicated records).
module Hmis::Ce
  class ClientProxy < GrdaWarehouseBase
    # For now, this is the GrdaWarehouse::Hud::Client representing the *destination* client.
    # In the future, we will add more client types (e.g. VSP)
    belongs_to :client, polymorphic: true, optional: false
    has_many :ce_match_candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :client_proxy_id, dependent: :destroy
    has_many :ce_match_candidate_events, class_name: 'Hmis::Ce::Match::CandidateEvent', foreign_key: :client_proxy_id, dependent: :destroy

    validates :client_id, presence: true, uniqueness: { scope: [:client_type] }
    validate :client_is_destination

    scope :for_warehouse_clients, -> { where(client_type: GrdaWarehouse::Hud::Client.sti_name) }

    scope :matching_search_term, ->(search_term) do
      search_term.strip!

      cp_t = Hmis::Ce::ClientProxy.arel_table
      c_t = GrdaWarehouse::Hud::Client.arel_table
      query = cp_t.join(c_t).
        on(cp_t[:client_id].eq(c_t[:id]).
        and(cp_t[:client_type].eq('GrdaWarehouse::Hud::Client'))).
        join_sources

      joins(query).merge(GrdaWarehouse::Hud::Client.text_search(search_term, sorted: false))
    end

    def self.apply_filters(input)
      Hmis::Filter::CeClientFilter.new(input).filter_scope(current_scope)
    end

    def client_is_destination
      errors.add :client, 'must be destination client' unless GrdaWarehouse::DataSource.destination_data_source_ids.include?(client.data_source_id)
    end

    # Join CE Client Proxies to most recent event per candidate pool. This ensures that even if the client
    # belongs to multiple candidate pools, we have the most recent calculated values for each pool.
    #
    # Note: this means that this filter will match if ANY of the candidate pools have a matching event.
    # For example,
    #   Client 1 belongs to Candidate Pool A, and their most recent event contains snapshot { "current_age": 78, "cde.custom_assessment.score": 5 }
    #   Client 1 belongs to Candidate Pool B, and their most recent event contains snapshot { "cde.custom_assessment.score": 6 }
    #
    # If filtering for clients with score "6" using `with_attribute` scope, Client 1 WILL be returned, even if the snapshot for Candidate Pool A was calculated more recently.
    scope :join_latest_event_per_candidate_pool, -> do
      latest_event_subquery = Hmis::Ce::Match::CandidateEvent.
        select('DISTINCT ON (candidate_pool_id, client_proxy_id) id, candidate_pool_id, client_proxy_id, snapshot').
        order('candidate_pool_id, client_proxy_id, created_at DESC')

      joins(ce_match_candidates: :candidate_pool).
        joins("LEFT JOIN (#{latest_event_subquery.to_sql}) latest_events ON latest_events.candidate_pool_id = ce_match_candidates.candidate_pool_id AND latest_events.client_proxy_id = ce_match_candidates.client_proxy_id").
        select('ce_client_proxies.*, latest_events.candidate_pool_id as candidate_pool_id, latest_events.snapshot AS latest_snapshot_for_candidate_pool').
        distinct
    end

    # Attribute filtering to use on scope that has already joined to events using join_latest_event_per_candidate_pool
    scope :filter_by_attribute, ->(key:, values:) do
      # Condition for JSON arrays.
      # Uses the ?| operator to check if the array contains any of the filter values.
      array_condition = <<-SQL
        jsonb_typeof(latest_events.snapshot -> :key) = 'array' AND
        (latest_events.snapshot -> :key)::jsonb ?| array[:values]
      SQL

      # Condition for single JSON values.
      # Uses the IN operator to check if the single value matches any of the filter values.
      single_value_condition = <<-SQL
        jsonb_typeof(latest_events.snapshot -> :key) != 'array' AND
        (latest_events.snapshot ->> :key) IN (:values)
      SQL

      # Combine conditions with OR
      combined_condition = <<-SQL
        (#{array_condition}) OR (#{single_value_condition})
      SQL

      # Apply the combined condition to the scope
      where(combined_condition, { key: key, values: Array.wrap(values).map(&:to_s) })
    end
  end
end
