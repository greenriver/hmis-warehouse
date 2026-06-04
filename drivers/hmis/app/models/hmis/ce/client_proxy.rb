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
    # Bulk-managed, does not log to paper_trail
    # Soft-deleted to avoid losing historical CE match data
    acts_as_paranoid

    # For now, this is the GrdaWarehouse::Hud::Client representing the *destination* client.
    # In the future, we will add more client types (e.g. VSP)
    belongs_to :client, polymorphic: true, optional: false
    belongs_to :destination_client, -> { where(ClientProxy.arel_table[:client_type].eq('GrdaWarehouse::Hud::Client')) }, foreign_key: 'client_id', class_name: 'GrdaWarehouse::Hud::Client', optional: true
    has_many :ce_match_candidates, class_name: 'Hmis::Ce::Match::Candidate', foreign_key: :client_proxy_id, dependent: :destroy
    # avoid dependent destroy/delete to preserve historical data
    has_many :ce_match_candidate_events, class_name: 'Hmis::Ce::Match::CandidateEvent', foreign_key: :client_proxy_id

    validates :client_id, presence: true, uniqueness: { scope: [:client_type] }
    validate :client_is_destination

    scope :for_warehouse_clients, -> { where(client_type: GrdaWarehouse::Hud::Client.sti_name) }

    scope :matching_search_term, ->(search_term) do
      search_term = search_term.strip

      cp_t = Hmis::Ce::ClientProxy.arel_table
      c_t = GrdaWarehouse::Hud::Client.arel_table
      query = cp_t.join(c_t).
        on(cp_t[:client_id].eq(c_t[:id]).
        and(cp_t[:client_type].eq('GrdaWarehouse::Hud::Client'))).
        join_sources

      joins(query).merge(GrdaWarehouse::Hud::Client.text_search(search_term, sorted: false))
    end

    scope :eligible_for_project_type, ->(project_types) do
      joins(ce_match_candidates: { candidate_pool: { unit_groups: :project } }).
        where(Hmis::Hud::Project.arel_table[:project_type].in(Array.wrap(project_types))).
        distinct
    end

    scope :eligible_for_project_group, ->(project_group_id) do
      project_ids = Hmis::ProjectGroup.project_ids_for(project_group_id)
      next none if project_ids.empty?

      joins(ce_match_candidates: { candidate_pool: { unit_groups: :project } }).
        where(Hmis::Hud::Project.arel_table[:id].in(project_ids)).
        distinct
    end

    # Narrow to proxies whose destination client's latest assessment has a CustomDataElement value in
    # `filter_values`. Uses a bounded subquery against DestinationClientLatestAssessment so Postgres
    # can restrict the view's DISTINCT ON to the current scope's client ids (not a correlated EXISTS).
    #
    # Must be chained on a relation (not called on the class) so `select(:client_id)` refers to the
    # current candidate set. `filter_values` must be non-empty; callers should skip blank filters.
    scope :matching_cde_values, ->(cded, filter_values) do
      where(
        client_id: Hmis::DestinationClientLatestAssessment.
          where(destination_client_id: select(:client_id)).
          with_cde_value(cded, filter_values).
          select(:destination_client_id).
          distinct,
      )
    end

    def self.apply_filters(input)
      Hmis::Filter::CeClientFilter.new(input).filter_scope(current_scope)
    end

    def client_is_destination
      errors.add :client, 'must be destination client' unless GrdaWarehouse::DataSource.destination_data_source_ids.include?(client.data_source_id)
    end
  end
end
