###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeClient < Types::BaseObject
    description 'A client who is eligible for Coordinated Entry (CE), represented by a ClientProxy. Underlying client record is Destination Client.'

    # For now, this type is only made available to CE Admins (on the Consolidated Waitlist).
    # When implementing issue #8005 to display list of eligible_unit_groups on the client dash, this may need to be expanded.
    def self.authorized?(object, context)
      super && context[:current_user].can_administrate_coordinated_entry?
    end

    available_filter_options do
      arg :search_term, String, required: false
      arg :project_type, [Types::HmisSchema::Enums::ProjectType], required: false, description: 'Filter to Clients that are eligible for the specified Project Types'
      arg :project_group_id, ID, required: false, description: 'Filter to Clients that are eligible for projects in the specified Project Group'
      arg :dynamic_filters, [Types::TableFilterValue], required: false
    end

    # object is a Hmis::Ce::ClientProxy
    field :id, ID, null: false, description: 'Client Proxy ID'
    field :destination_client_id, ID, null: false # may need to make this nullable in the future for other CE Client types (Eg VSP)
    field :viewable_source_client_ids, [ID], null: false, description: 'IDs of the source clients associated with this client that belong to this HMIS data source and are viewable by the current user'
    field :client_name, String, null: false
    field :client_attributes, GraphQL::Types::JSON, null: false, description: 'Current values for the given expression keys' do
      # TODO: make `keys` required once every client passes it explicitly; then remove inference from
      # global CE table configuration (same lookup as TableConfigLookup#ce_clients_global_config).
      argument :keys, [String], required: false, description: 'Keys whose values should be returned. Same format as TableColumnConfig keys.'
    end
    field :external_ids, [Types::HmisSchema::ExternalIdentifier], null: false
    field :eligible_unit_groups, HmisSchema::CeEligibleUnitGroup.page_type, null: false, description: 'Unit groups that this client is a candidate for', nodes_count: lambda(&:size) do
      filters_argument HmisSchema::CeEligibleUnitGroup
    end

    # All the unit groups that this client is a candidate for.
    # N+1 query; do not use in batch for multiple clients.
    def eligible_unit_groups(filters: nil)
      scope = object.ce_match_candidates.
        joins(candidate_pool: :unit_groups)

      if filters&.project_type.present?
        p_t = Hmis::Hud::Project.arel_table
        scope = scope.joins(candidate_pool: { unit_groups: :project }).
          where(p_t[:project_type].in(filters.project_type))
      end

      scope.select('ce_match_candidates.*, hmis_unit_groups.id AS unit_group_id').distinct.order(updated_at: :desc)
    end

    def destination_client_id
      destination_client.id
    end

    def viewable_source_client_ids
      source_clients.select do |source_client|
        current_permission?(permission: :can_view_clients, entity: source_client)
      end.map(&:id).sort
    end

    def client_name
      load_destination_client_name(destination_client: destination_client).presence || "CE Client #{object.id}"
    end

    # Resolve provided keys on the destination client. Keys are in FieldMap format, e.g. 'cde.custom_assessment.my_score'
    # If keys are not provided, infer keys from the CE clients table column config (for backwards compatibility).
    # Once frontend always passes keys, we can adjust this to require keys, remove inference, and return empty if keys are blank.
    def client_attributes(keys: nil)
      keys = keys.presence || inferred_ce_clients_table_column_keys
      return {} if keys.blank?

      dataloader.with(Sources::CeExpressionFieldValuesSource, keys: keys).load(object.client_id)
    end

    def external_ids
      mci_ids = source_clients.flat_map { |client| load_ar_association(client, :ac_hmis_mci_ids) }.uniq
      Hmis::Hud::ClientExternalIdentifierCollection.new(
        client: object, # unused, since we are only returning MCI IDs here
        ac_hmis_mci_ids: mci_ids,
      ).mci_identifiers
    end

    private

    # Infer keys to resolve on `client_attributes` by checking global CE clients table column config.
    # This should be removed once every client passes `keys` explicitly.
    # Memoize on the request context so resolving many `CeClient`s does not repeat the lookup.
    def inferred_ce_clients_table_column_keys
      cache_key = "inferred_ce_clients_global_column_keys:#{current_user.hmis_data_source_id}"
      return context[cache_key] if context.key?(cache_key)

      context[cache_key] = Hmis::TableConfiguration.detect_ce_clients_global_config(data_source_id: current_user.hmis_data_source_id)&.column_keys
    end

    def destination_client
      raise 'unexpected client type' unless object.client_type == GrdaWarehouse::Hud::Client.sti_name

      load_ar_scope(scope: GrdaWarehouse::Hud::Client.all, id: object.client_id)
    end

    def source_clients
      load_ar_association(destination_client, :hmis_source_clients)
    end
  end
end
