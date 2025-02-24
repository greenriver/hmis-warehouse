FactoryBot.define do
  factory :grda_warehouse_client_notes_expired_alert, class: 'GrdaWarehouse::ClientNotes::Alert' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note { 'Test' }
    expiration_date { Date.current - 1.days }
  end

  factory :grda_warehouse_client_notes_active_alert, class: 'GrdaWarehouse::ClientNotes::Alert' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note { 'Test' }
    expiration_date { Date.current + 1.days }
  end

  factory :grda_warehouse_client_notes_no_expiration, class: 'GrdaWarehouse::ClientNotes::Alert' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note { 'Test' }
    expiration_date { nil }
  end

  factory :grda_warehouse_client_notes_expiration_today, class: 'GrdaWarehouse::ClientNotes::Alert' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note { 'Test' }
    expiration_date { Date.current }
  end
end
