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
    field :ce_client, HmisSchema::CeClient, null: true do |field|
      field.argument :id, ID, 'Client Proxy ID', required: true
    end
    field :client_attribute_columns, [Types::HmisSchema::KeyValue], null: false, description: 'Columns available in the consolidated waitlist'
    field :available_filters, [Types::DynamicFilterConfig], null: false

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

    def ce_client(id:)
      Hmis::Ce::ClientProxy.find_by(id: id)
    end

    def client_attribute_columns
      # use a flag on CDED to determine this, or have a separate table for configuring consolidated waitlist. column configuration is gonna be a common things
      [
        { key: 'cde.custom_assessment.hna_ce_test_1_prioritization_score', value: 'AHA score' },
        { key: 'cde.custom_assessment.hna_ce_test_1_household_type', value: 'Household Type' },
        # Assessment Date-- add to eligibility requirements to be like "it must be present" as a workaround?
        # do we need an expression to coalesce veteran status questions?? to avoid this, collect onto same CDED in form?
      ]
    end

    def available_filters
      [
        {
          key: 'cde.custom_assessment.hna_ce_test_1_prioritization_score',
          label: 'AHA Score',
          values: ['1', '2', '3', '4', '5', '6', '7', '8', '9', '10'],
        },
      ]
    end
  end
end
