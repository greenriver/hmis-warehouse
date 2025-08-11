###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeConsolidatedWaitlistClient < Types::BaseObject
    # object is a Hmis::Ce::ClientProxy
    field :id, ID, null: false
    field :destination_client_id, ID, null: false
    field :source_client_ids, [ID], null: false
    field :client_name, String, null: false
    # aggregate client_attributes across candidate pools (most recent update per client)
    field :aggregated_client_attributes, GraphQL::Types::JSON, null: false
    # .... info about the different candidate pools they belong to...
    # field :candidate_pools

    def unit_group_candidacy
      
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
      # todo dedup copied from from CeCandidate
      first_viewable_name = source_clients.sort_by(&:id).find do |client|
        current_permission?(permission: :can_view_clients, entity: client) && current_permission?(permission: :can_view_client_name, entity: client)
      end&.brief_name

      first_viewable_name || "Candidate #{object.id}"
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
