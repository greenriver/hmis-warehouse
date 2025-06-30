# frozen_string_literal: true

FactoryBot.define do
  factory :grda_warehouse_client_change_marker, class: 'GrdaWarehouse::ClientChangeMarker' do
    association :client, factory: :fixed_destination_client
    current_version { 1 }
    processed_version { 0 }
  end
end
