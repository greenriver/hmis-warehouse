###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_warehouse_clients_processed, class: 'GrdaWarehouse::WarehouseClientsProcessed' do
    transient do
      client { nil }
    end

    routine { 'service_history' }
    days_homeless_last_three_years { 0 }

    after(:build) do |processed, evaluator|
      # Use provided client or client_id, or create a new one
      if evaluator.client
        processed.client_id ||= evaluator.client.id
        processed.warehouse_client ||= build(:warehouse_client, destination_id: evaluator.client.id)
      elsif processed.client_id.nil?
        # No client or client_id provided, create defaults
        dest_client = build(:grda_warehouse_hud_client)
        processed.client_id = dest_client.id
        processed.warehouse_client = build(:warehouse_client, destination_id: dest_client.id)
      else
        # client_id was explicitly provided, use it
        processed.warehouse_client ||= build(:warehouse_client, destination_id: processed.client_id)
      end
    end
  end
end
