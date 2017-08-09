FactoryGirl.define do
  factory :grda_warehouse_client_notes_chronic_justification, class: 'GrdaWarehouse::ClientNotes::ChronicJustification' do
    association :client, factory: :grda_warehouse_hud_client
    user
    note 'Test'
    # type 'GrdaWarehouse::ClientNotes::ChronicJustification'
    # created_at Date.current
    # updated_at
    # deleted_at
  end
end
