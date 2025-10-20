###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_warehouse_clients_processed, class: 'GrdaWarehouse::WarehouseClientsProcessed' do
    association :client, factory: :grda_warehouse_hud_client
    routine { 'service_history' }
    days_homeless_last_three_years { 0 }
  end
end
