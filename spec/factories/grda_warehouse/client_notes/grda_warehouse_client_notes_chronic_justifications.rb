FactoryGirl.define do
  factory :grda_warehouse_client_notes_chronic_justification, class: 'GrdaWarehouse::ClientNotes::ChronicJustification' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note 'Test'
    type 'GrdaWarehouse::ClientNotes::ChronicJustification'
  end
end
