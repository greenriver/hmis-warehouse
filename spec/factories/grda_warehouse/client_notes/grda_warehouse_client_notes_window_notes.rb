FactoryGirl.define do
  factory :grda_warehouse_client_notes_window_note, class: 'GrdaWarehouse::ClientNotes::WindowNote' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note 'Test'
  end
end
