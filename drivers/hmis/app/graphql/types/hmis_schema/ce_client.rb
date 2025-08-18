###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeClient < Types::BaseObject
    description 'A client who is a candidate for Coordinated Entry (CE), represented by a ClientProxy. Underlying client record is Destination Client.'

    available_filter_options do
      arg :search_term, String, required: false
      arg :dynamic_filters, [Types::TableFilterValue], required: false
    end

    # object is a Hmis::Ce::ClientProxy
    field :id, ID, null: false # ce client proxy id
    field :destination_client_id, ID, null: false
    field :source_client_ids, [ID], null: false, description: 'IDs of the source clients associated with this client that belong to this HMIS data source' # fixme: using this for linking, but really we would need to check which of these clients are viewable
    field :client_name, String, null: false
    field :external_ids, [Types::HmisSchema::ExternalIdentifier], null: false
    field :aggregated_client_attributes, GraphQL::Types::JSON, null: false, description: 'Aggregated client attributes from all candidate pools'
    field :eligible_unit_groups, HmisSchema::CeEligibleUnitGroup.page_type, null: false, description: 'Unit groups that this client is a candidate for', nodes_count: ->(all_nodes) { all_nodes.count(:id) }

    # CE Admins only, for now. Expand if showing on Client dashboard?
    def self.authorized?(object, context)
      super && context[:current_user].can_administrate_coordinated_entry?
    end

    # All the unit groups that this client is a candidate for.
    # N+1 query; do not use in batch for multiple clients.
    def eligible_unit_groups
      # note: could incorporate the latest_event subquery too if pool-specific attributes need to be resolved
      object.ce_match_candidates.
        joins(candidate_pool: :unit_groups).
        select('ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id').
        distinct
    end

    def destination_client_id
      destination_client.id
    end

    def source_client_ids
      load_ar_association(destination_client, :warehouse_client_destination).
        select { |wcd| wcd.data_source_id == current_user.hmis_data_source_id }.
        map(&:source_id)
    end

    def client_name
      load_destination_client_name(destination_client: destination_client).presence || "CE Client #{object.id}"
    end

    # Aggregate the most recent eligibility/prioritization attributes across all candidate pools the client is in.
    # Sort by event date before merging, so that the most recently calculated attributes are favored
    def aggregated_client_attributes
      events = load_ar_association(object, :ce_match_candidate_events)
      events.group_by(&:candidate_pool_id).values.
        map { |arr| arr.max_by(&:created_at) }.
        sort_by(&:created_at).
        map(&:snapshot).reduce({}, :merge)
    end

    def external_ids
      mci_ids = source_clients.flat_map { |client| load_ar_association(client, :ac_hmis_mci_ids) }.uniq
      Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: object, # unused, since we are only returning MCI IDs here
        ac_hmis_mci_ids: mci_ids,
      ).mci_identifiers
    end

    private

    def destination_client
      raise 'unexpected client type' unless object.client_type == GrdaWarehouse::Hud::Client.sti_name

      load_ar_scope(scope: GrdaWarehouse::Hud::Client.all, id: object.client_id)
    end

    def source_clients
      load_ar_association(destination_client, :hmis_source_clients)
    end
  end
end
