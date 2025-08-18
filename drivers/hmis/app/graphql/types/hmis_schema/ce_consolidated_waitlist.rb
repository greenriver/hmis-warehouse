###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeConsolidatedWaitlist < Types::BaseObject
    skip_activity_log

    field :ce_clients, HmisSchema::CeClient.page_type, null: false, description: 'Clients who belong to at least one CE candidate pool', nodes_count: ->(all_nodes) { all_nodes.count(:id) } do
      filters_argument HmisSchema::CeClient
    end

    field :table_column_configs, [Types::TableColumnConfig], null: false, description: 'Columns available in the consolidated waitlist'
    field :table_filter_configs, [Types::TableFilterConfig], null: false

    def self.authorized?(object, context)
      super && context[:current_user].can_administrate_coordinated_entry?
    end

    def ce_clients(filters: nil)
      scope = Hmis::Ce::ClientProxy.for_warehouse_clients.
        joins(:ce_match_candidates).
        distinct.order(:id)

      scope = scope.apply_filters(filters) if filters
      scope
    end

    def table_column_configs
      table_configuration&.columns
    end

    def table_filter_configs
      table_configuration&.filters
    end

    private

    def table_configuration
      Hmis::TableConfiguration.for_consolidated_waitlist(data_source_id: current_user.hmis_data_source_id)
    end
  end
end
